// SPDX-FileCopyrightText: 2026 Andrea Bogazzi
// SPDX-License-Identifier: GPL-3.0-or-later
// Date: 04-11-2026

#include "Vjt08.h"
#include "verilated.h"
#include "ymfm_opn.h"
#include <array>
#include <cmath>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>
#include <sstream>
#include <filesystem>

struct Reference : ymfm::ymfm_interface {
    uint64_t clock = 0, busy_end = 0;
    std::array<uint64_t,2> deadline{};
    std::array<uint8_t,2> io_in{{0x5a,0xa5}}, io_out{};
    bool irq = false;
    std::array<uint8_t,8192> rhythm{};
    std::array<uint8_t,262144> memory{};
    Reference() {
        for(unsigned i=0;i<memory.size();++i) memory[i]=uint8_t((i*13)^(i>>3));
        std::ifstream rom("build/rhythm.bin",std::ios::binary);
        if(!rom.read(reinterpret_cast<char*>(rhythm.data()),rhythm.size())) throw std::runtime_error("Missing build/rhythm.bin");
    }
    void ymfm_set_timer(uint32_t n, int32_t duration) override {
        deadline[n] = duration < 0 ? 0 : clock + duration;
    }
    void ymfm_set_busy_end(uint32_t duration) override { busy_end = clock + duration; }
    bool ymfm_is_busy() override { return clock < busy_end; }
    void ymfm_update_irq(bool asserted) override { irq = asserted; }
    uint8_t ymfm_external_read(ymfm::access_class type, uint32_t address) override {
        return type == ymfm::ACCESS_IO ? io_in[address & 1] : type==ymfm::ACCESS_ADPCM_A ? rhythm[address & 8191] : type==ymfm::ACCESS_ADPCM_B ? memory[address & 262143] : 0;
    }
    void ymfm_external_write(ymfm::access_class type, uint32_t address, uint8_t value) override {
        if(type == ymfm::ACCESS_IO) io_out[address & 1] = value;
        if(type == ymfm::ACCESS_ADPCM_B) memory[address & 262143] = value;
    }
    void tick() {
        ++clock;
        for(unsigned n=0;n<2;++n) if(deadline[n] && deadline[n]<=clock) {
            deadline[n]=0;
            m_engine->engine_timer_expired(n);
        }
    }
};

struct Pair { double jl, jr, ml, mr, jp, mp; };
struct Rig {
    Reference reference;
    std::unique_ptr<ymfm::ym2608> model;
    unsigned audio_phase=0;
    Vjt08 rtl;
    ymfm::ym2608::output_data output{};
    unsigned checks = 0, reference_read=0;
    std::array<uint8_t,262144> memory{};
    bool mem_pending=false, mem_done=false;
    unsigned mem_delay=0, mem_latency=8, mem_address=0;
    bool mem_write=false;
    uint8_t mem_value=0;
    uint64_t sample_count = 0;
    std::ofstream bus{"reports/bus.csv"};
    Rig() {
        memory=reference.memory;
        rtl.adpcm_ok=0;rtl.adpcm_data=0;
        bus << "clock,label,port,rtl,mame,mask\n";
        rtl.cs_n=1; rtl.wr_n=1; rtl.rd_n=1;
        rtl.IOA_in=0x5a; rtl.IOB_in=0xa5; rtl.addr=0; rtl.din=0;
        reset();
    }
    void reset(unsigned settle=2048) {
        rtl.cs_n=1; rtl.wr_n=1; rtl.rd_n=1; rtl.rst=1;
        reference.deadline={0,0};reference.busy_end=reference.clock;reference.irq=false;
        model=std::make_unique<ymfm::ym2608>(reference);
        model->set_fidelity(ymfm::OPN_FIDELITY_MAX);
        model->reset();
        wait(2048);
        model->generate(&output);
        audio_phase=0;
        rtl.rst=0;
        wait(settle);
    }
    void tick() {
        for(unsigned sub=0;sub<4;++sub) {
            rtl.cen=sub==0;
            if(!rtl.adpcm_cs) { mem_pending=false; mem_done=false; }
            if(rtl.adpcm_cs && !mem_pending && !mem_done) {
                mem_pending=true; mem_delay=mem_latency; mem_address=rtl.adpcm_addr; mem_write=rtl.adpcm_we; mem_value=rtl.adpcm_din;
            }
            rtl.adpcm_ok=0;
            if(mem_pending && --mem_delay==0) {
                if(mem_write) memory[mem_address & 262143]=mem_value;
                rtl.adpcm_data=memory[mem_address & 262143];
                rtl.adpcm_ok=1; mem_pending=false;mem_done=true;
            }
            rtl.clk=0; rtl.eval();
            rtl.rhythm_data=reference.rhythm[rtl.rhythm_addr & 8191]; rtl.eval();
            rtl.clk=1; rtl.eval();
            if(rtl.snd_sample) ++sample_count;
        }
        reference.tick();
        if(!rtl.rst && ++audio_phase==8) { audio_phase=0;model->generate(&output); }
    }
    void wait(unsigned clocks) { while(clocks--) tick(); }
    void check(bool condition, const std::string &label) {
        ++checks;
        if(!condition) throw std::runtime_error(label);
    }
    void write(unsigned port, unsigned value) {
        rtl.addr=port; rtl.din=value; rtl.cs_n=0; rtl.wr_n=0; rtl.rd_n=1;
        model->write(port,value);
        tick();
        rtl.cs_n=1; rtl.wr_n=1;
        wait(31);
    }
    void reg(unsigned bank,unsigned address,unsigned value) {
        write(bank*2,address); write(bank*2+1,value); wait(256);
    }
    unsigned read(unsigned port) {
        rtl.addr=port; rtl.cs_n=0; rtl.rd_n=0; rtl.wr_n=1;
        wait(2);
        unsigned value=rtl.dout;
        reference_read=model->read(port);
        rtl.cs_n=1; rtl.rd_n=1;
        wait(1);
        return value;
    }
    void same(unsigned port,const std::string &label,unsigned mask=0xff) {
        unsigned actual=read(port), expected=reference_read;
        bus << reference.clock << ',' << label << ',' << port << ',' << actual << ',' << expected << ',' << mask << '\n';
        check((actual&mask)==(expected&mask),label+" RTL="+std::to_string(actual)+" MAME="+std::to_string(expected));
    }
    std::vector<Pair> collect(const std::string &name,unsigned count=4096,unsigned layer=0) {
        std::ofstream csv("reports/"+name+".csv");
        csv << "clock,rtl_l,rtl_r,mame_l,mame_r,rtl_psg,mame_psg\n";
        std::vector<Pair> data;
        for(unsigned i=0;i<count;++i) {
            wait(144);
            Pair p{layer==1?double(int32_t(rtl.rhythm_left<<13)>>13):layer==2?double(int16_t(rtl.adpcm_left)):double(int16_t(rtl.fm_left)),layer==1?double(int32_t(rtl.rhythm_right<<13)>>13):layer==2?double(int16_t(rtl.adpcm_right)):double(int16_t(rtl.fm_right)),
                double(output.data[0]),double(output.data[1]),double(rtl.psg_snd),double(output.data[2])};
            data.push_back(p);
            csv << reference.clock << ',' << p.jl << ',' << p.jr << ',' << p.ml << ',' << p.mr << ',' << p.jp << ',' << p.mp << '\n';
        }
        return data;
    }
    void sample_period(unsigned expected,const std::string &label) {
        wait(1024);
        uint64_t before=sample_count;
        wait(expected*128);
        check(sample_count-before==128,label+" expected sample period "+std::to_string(expected));
    }
    void tone(unsigned channel,unsigned pan) {
        unsigned bank=channel/3, ch=channel%3;
        for(unsigned slot=0;slot<4;++slot) {
            reg(bank,0x30+slot*4+ch,1);
            reg(bank,0x40+slot*4+ch,0);
            reg(bank,0x50+slot*4+ch,31);
            reg(bank,0x60+slot*4+ch,0);
            reg(bank,0x70+slot*4+ch,0);
            reg(bank,0x80+slot*4+ch,15);
        }
        reg(bank,0xb0+ch,7);
        reg(bank,0xb4+ch,pan);
        reg(bank,0xa4+ch,0x24);
        reg(bank,0xa0+ch,0);
        reg(0,0x28,0x10+ch+(bank?4:0));
        wait(10000);
    }
};

static double rms(const std::vector<Pair>& v,unsigned column) {
    double sum=0;
    for(size_t i=256;i<v.size();++i) {
        double x=column==0?v[i].jl:column==1?v[i].jr:column==2?v[i].ml:column==3?v[i].mr:column==4?v[i].jp:v[i].mp;
        sum+=x*x;
    }
    return std::sqrt(sum/(v.size()-256));
}

static double correlation(const std::vector<Pair>& v,unsigned channel) {
    double best=-1;
    for(int lag=-16;lag<=16;++lag) {
        double xy=0,xx=0,yy=0;
        for(int i=256;i<int(v.size())-32;++i) {
            double x=channel?v[i].jr:v[i].jl, y=channel?v[i+lag].mr:v[i+lag].ml;
            xy+=x*y; xx+=x*x; yy+=y*y;
        }
        if(xx>0 && yy>0) best=std::max(best,xy/std::sqrt(xx*yy));
    }
    return best;
}

struct PCMResult { int lag; unsigned errors; int max_error; };
static PCMResult pcm_compare(const std::vector<Pair>& v,int low=-4,int high=0,int skip=256) {
    PCMResult best{0,unsigned(v.size()),65535};
    for(int lag=low;lag<=high;++lag) {
        PCMResult candidate{lag,0,0};
        for(int i=skip;i<int(v.size())-32;++i) {
            int dl=int(v[i].jl)-int(v[i+lag].ml), dr=int(v[i].jr)-int(v[i+lag].mr);
            candidate.errors+=(dl!=0 || dr!=0);
            candidate.max_error=std::max(candidate.max_error,std::max(std::abs(dl),std::abs(dr)));
        }
        if(candidate.errors<best.errors || (candidate.errors==best.errors && candidate.max_error<best.max_error)) best=candidate;
    }
    return best;
}

static void wav(const std::string &path,const std::vector<Pair>& data,bool reference) {
    std::ofstream out(path,std::ios::binary);
    auto u16=[&](unsigned x){out.put(x&255);out.put((x>>8)&255);};
    auto u32=[&](unsigned x){u16(x&65535);u16(x>>16);};
    out.write("RIFF",4);u32(36+data.size()*4);out.write("WAVEfmt ",8);u32(16);u16(1);u16(2);
    u32(55556);u32(55556*4);u16(4);u16(16);out.write("data",4);u32(data.size()*4);
    for(const auto &p:data) {
        u16(uint16_t(int16_t(reference?p.ml:p.jl)));
        u16(uint16_t(int16_t(reference?p.mr:p.jr)));
    }
}
static int replay_trace(const std::string &path,const std::string &component="all") {
    if(component!="all" && component!="fm" && component!="rhythm" && component!="delta") throw std::runtime_error("Unknown trace component");
    struct Event { uint64_t clock;unsigned port,data; };
    std::ifstream input(path);std::vector<Event> events;std::string line;
    while(std::getline(input,line)) {
        std::replace(line.begin(),line.end(),',',' ');std::istringstream row(line);Event event;
        if(!(row>>event.clock>>event.port>>event.data) || event.port>3 || event.data>255)
            throw std::runtime_error("Invalid sound trace row");
        if(!events.empty() && event.clock<events.back().clock) throw std::runtime_error("Nonmonotonic sound trace");
        events.push_back(event);
    }
    if(events.empty()) throw std::runtime_error("Empty sound trace");
    Rig t;
    std::ifstream samples("build/external.bin",std::ios::binary);
    if(!samples) throw std::runtime_error("YM2608_SAMPLES must point to the game's sample ROM");
    t.memory.fill(255);
    samples.read(reinterpret_cast<char*>(t.memory.data()),t.memory.size());
    t.reference.memory=t.memory;
    t.reset(0);
    std::vector<Pair> audio;
    uint64_t duration=events.back().clock+2000000;
    size_t next=0;
    unsigned selected=0;
    std::ofstream csv("reports/game-audio.csv");csv<<"clock,rtl_l,rtl_r,mame_l,mame_r,rtl_psg,mame_psg\n";
    for(uint64_t clock=0;clock<duration;++clock) {
        t.rtl.cs_n=1;t.rtl.wr_n=1;t.rtl.rd_n=1;
        if(next<events.size() && events[next].clock==clock) {
            auto e=events[next++];
            if(!(e.port&1)) selected=((e.port>>1)<<8)|e.data;
            bool rhythm=selected>=0x10 && selected<0x20;
            bool delta=selected>=0x100 && selected<0x110;
            bool enabled=component=="all" || (component=="fm" && !rhythm && !delta) || (component=="rhythm" && rhythm) || (component=="delta" && delta);
            if(!(e.port&1) || enabled) {
                t.rtl.addr=e.port;t.rtl.din=e.data;t.rtl.cs_n=0;t.rtl.wr_n=0;
                t.model->write(e.port,e.data);
            }
            if(next<events.size() && events[next].clock==clock) throw std::runtime_error("Multiple bus writes in one chip clock");
        }
        t.tick();
        if(clock%144==143) {
            Pair p{double(int16_t(t.rtl.snd_left)),double(int16_t(t.rtl.snd_right)),double(t.output.data[0]),double(t.output.data[1]),double(t.rtl.psg_snd),double(t.output.data[2])};
            audio.push_back(p);
            csv<<clock<<','<<p.jl<<','<<p.jr<<','<<p.ml<<','<<p.mr<<','<<p.jp<<','<<p.mp<<'\n';
        }
    }
    double l=correlation(audio,0),r=correlation(audio,1);
    wav("reports/game-rtl.wav",audio,false);wav("reports/game-mame.wav",audio,true);
    std::ofstream result("reports/result.json");
    result<<"{\"status\":\"completed\",\"component\":\""<<component<<"\",\"scope\":\"captured game chip writes, digital stereo output; SSG kept separate\",\"writes\":"<<events.size()<<",\"samples\":"<<audio.size()<<",\"correlation_left\":"<<l<<",\"correlation_right\":"<<r<<",\"gain_left\":"<<rms(audio,0)/rms(audio,2)<<",\"gain_right\":"<<rms(audio,1)/rms(audio,3)<<"}\n";
    std::cout<<"Game trace: "<<events.size()<<" writes, correlation L="<<l<<" R="<<r<<"; reports/game-{rtl,mame}.wav\n";
    return 0;
}

int main(int argc,char **argv) {
    Verilated::commandArgs(argc,argv);
    try {
        if((argc==3 || argc==4) && std::string(argv[1])=="--trace") return replay_trace(argv[2],argc==4?argv[3]:"all");
        Rig t;
        t.wait(1); t.check(t.rtl.dout==0xff,"inactive bus read value");
        t.same(0,"reset status"); t.same(2,"reset extended status");
        t.write(0,0xff); t.same(1,"device identification");
        t.write(2,0xff); t.same(1,"bank mismatch read");
        t.write(0,0); t.write(3,0x77); t.same(1,"mismatched bank write rejected");
        t.write(0,0); t.write(1,0x22); t.same(0,"busy during register processing",0x80);
        t.wait(256); t.same(0,"busy released",0x80);
        for(unsigned address=0;address<14;++address) {
            t.reg(0,address,0xa5);
            unsigned mask=(address==1 || address==3 || address==5 || address==13)?15:
                (address==6 || (address>=8 && address<=10))?31:255;
            t.same(1,"SSG register "+std::to_string(address),mask);
        }
        t.reg(0,7,0x3f); t.reg(0,14,0x33); t.reg(0,15,0xcc);
        t.write(0,14); t.same(1,"GPIO A input");
        t.write(0,15); t.same(1,"GPIO B input");
        t.reg(0,7,0xff);
        t.reg(0,14,0x66); t.reg(0,15,0x99);
        t.check(t.rtl.IOA_oe && t.rtl.IOB_oe,"GPIO direction");
        t.check(t.rtl.IOA_out==t.reference.io_out[0] && t.rtl.IOB_out==t.reference.io_out[1],"GPIO output");
        t.reg(0,7,0x3f);
        t.reg(0,7,0x3e);
        t.reg(0,8,15); t.reg(0,9,0); t.reg(0,10,0);
        t.reg(0,0,32); t.reg(0,1,0);
        auto psg=t.collect("psg");
        t.check(rms(psg,4)>0 && rms(psg,5)>0,"SSG produces sound");
        double pmin=psg[256].jp,pmax=pmin,mmin=psg[256].mp,mmax=mmin;
        for(size_t i=256;i<psg.size();++i) {
            pmin=std::min(pmin,psg[i].jp);pmax=std::max(pmax,psg[i].jp);
            mmin=std::min(mmin,psg[i].mp);mmax=std::max(mmax,psg[i].mp);
        }
        t.check(pmax>pmin && mmax>mmin,"SSG tone is oscillating");
        unsigned pedges=0,medges=0;
        for(size_t i=257;i<psg.size();++i) {
            pedges+=(psg[i-1].jp<(pmin+pmax)/2 && psg[i].jp>=(pmin+pmax)/2);
            medges+=(psg[i-1].mp<(mmin+mmax)/2 && psg[i].mp>=(mmin+mmax)/2);
        }
        t.check(std::abs(int(pedges)-int(medges))<=1,"SSG tone frequency");
        t.reg(0,8,0);
        t.sample_period(144,"default prescaler");
        t.write(2,0x2f); t.sample_period(144,"upper bank cannot change prescaler");
        t.write(0,0x2e); t.sample_period(72,"prescale three");
        t.write(0,0x2d); t.sample_period(144,"prescale six restored");
        t.write(0,0x2f); t.sample_period(48,"prescale two");
        t.write(0,0x2d); t.sample_period(144,"prescale six after two");
        t.tone(3,0x80);
        auto disabled=t.collect("three_channel",1024);
        t.check(rms(disabled,0)==0 && rms(disabled,2)==0,"upper FM channels reset disabled");
        t.reg(0,0x29,0x9f);
        auto left=t.collect("fm_left");
        t.check(rms(left,0)>100 && rms(left,2)>100,"six-channel enable");
        t.check(rms(left,1)==0 && rms(left,3)==0,"left-only stereo routing");
        double corr=correlation(left,0), gain=rms(left,0)/rms(left,2);
        std::cout << "FM correlation=" << corr << " gain=" << gain << '\n';
        t.check(corr>0.99,"FM waveform correlation");
        t.check(gain>0.95 && gain<1.05,"FM amplitude");
        t.reg(1,0xb4,0x40);
        auto right=t.collect("fm_right");
        t.check(rms(right,0)==0 && rms(right,2)==0 && rms(right,1)>100 && rms(right,3)>100,"right-only stereo routing");
        t.reg(0,0x29,0x1f);
        auto muted=t.collect("three_channel_again",1024);
        t.check(rms(muted,0)==0 && rms(muted,1)==0 && rms(muted,2)==0 && rms(muted,3)==0,"six-to-three transition");
        t.reg(0,0x24,0xff); t.reg(0,0x25,3); t.reg(0,0x27,0x05);
        t.wait(4096); t.same(0,"timer A overflow",3);
        t.check(!t.rtl.irq_n && t.reference.irq,"timer A IRQ");
        t.reg(0,0x29,0x1e);
        t.check(t.rtl.irq_n && !t.reference.irq,"timer A global IRQ mask");
        t.reg(0,0x27,0x10); t.wait(256); t.same(0,"timer A clear",3);
        t.reg(0,0x26,0xff); t.reg(0,0x29,0x1f); t.reg(0,0x27,0x0a);
        t.wait(5000); t.same(0,"timer B overflow",3);
        t.check(!t.rtl.irq_n && t.reference.irq,"timer B IRQ");
        t.reg(0,0x27,0x20); t.wait(256); t.same(0,"timer B clear",3);
        t.reg(1,0x10,0); t.same(2,"BRDY unmasked idle status");
        t.check(!t.rtl.irq_n && t.reference.irq,"BRDY IRQ mask path");
        t.reg(1,0x10,0x1c); t.same(2,"ADPCM mask restored");
        std::ofstream pcm_report("reports/fm-pcm-comparison.csv");
        pcm_report << "channel,lag_samples,differing_samples,maximum_error,compared_samples\n";
        for(unsigned channel=0;channel<6;++channel) {
            t.reset();
            t.reg(0,0x29,0x9f);
            t.tone(channel,0xc0);
            auto data=t.collect("fm_channel_"+std::to_string(channel),2048);
            t.check(rms(data,0)>100 && rms(data,2)>100,"channel audible "+std::to_string(channel));
            t.check(correlation(data,0)>0.99,"channel waveform "+std::to_string(channel));
            double ratio=rms(data,0)/rms(data,2);
            t.check(ratio>0.95 && ratio<1.05,"channel gain "+std::to_string(channel));
            auto comparison=pcm_compare(data);
            pcm_report << channel+1 << ',' << comparison.lag << ',' << comparison.errors << ',' << comparison.max_error << ',' << data.size()-288 << '\n';
            t.check(comparison.errors==0,"channel PCM after measured pipeline alignment "+std::to_string(channel));
            t.reg(0,0x28,channel%3+(channel>=3?4:0));
            t.wait(20000);
        }
        for(unsigned voice=0;voice<6;++voice) {
            t.reset();
            t.reg(0,0x11,63);t.reg(0,0x18+voice,0xdf);t.reg(0,0x10,1<<voice);
            auto rhythm=t.collect("rhythm_"+std::to_string(voice),8192,true);
            double c=correlation(rhythm,0), g=rms(rhythm,0)/rms(rhythm,2);
            std::cout << "Rhythm " << voice << " correlation=" << c << " gain=" << g << std::endl;
            t.check(rms(rhythm,0)>0 && rms(rhythm,2)>0,"rhythm audible "+std::to_string(voice));
            t.check(c>0.95,"rhythm waveform "+std::to_string(voice));
            t.check(g>0.95 && g<1.05,"rhythm gain "+std::to_string(voice));
            t.check(pcm_compare(rhythm,-2,0,16).errors==0,"rhythm PCM "+std::to_string(voice));
        }
        t.reset();
        t.reg(1,1,0xc1);t.reg(1,2,0);t.reg(1,3,0);t.reg(1,4,0x7f);t.reg(1,5,0);
        t.reg(1,9,0xff);t.reg(1,10,0x7f);t.reg(1,11,255);t.reg(1,12,0xff);t.reg(1,13,0xff);
        t.reg(1,0,0xa0);
        auto delta=t.collect("delta_t",8192,2);
        double dc=correlation(delta,0),dg=rms(delta,0)/rms(delta,2);
        std::cout << "DeltaT correlation=" << dc << " gain=" << dg << std::endl;
        t.check(dc>0.99,"Delta-T waveform");t.check(dg>0.95 && dg<1.05,"Delta-T gain");
        t.check(pcm_compare(delta,-4,4,16).errors==0,"Delta-T PCM");
        t.same(2,"Delta-T playback status");
        for(unsigned delta_n: {0x0100u,0x4321u,0xffffu}) {
            t.reset();t.mem_latency=64;
            t.reg(1,1,0xc1);t.reg(1,4,0x1f);t.reg(1,5,0);
            t.reg(1,11,255);t.reg(1,9,delta_n&255);t.reg(1,10,delta_n>>8);t.reg(1,0,0xa0);
            auto data=t.collect("delta_rate_"+std::to_string(delta_n),8192,2);
            double c=correlation(data,0), g=rms(data,0)/rms(data,2);
            std::cout << "DeltaN " << delta_n << " correlation=" << c << " gain=" << g << std::endl;
            t.check(c>0.99,"Delta-N waveform "+std::to_string(delta_n));
            t.check(g>0.95 && g<1.05,"Delta-N level "+std::to_string(delta_n));
            t.check(pcm_compare(data,-4,4,16).errors==0,"Delta-N PCM");
            t.same(2,"Delta-N status");
        }
        t.mem_latency=8;
        for(bool repeat: {false,true}) {
            t.reset();
            t.reg(1,1,0x81);t.reg(1,11,255);t.reg(1,4,0);t.reg(1,9,0xff);t.reg(1,10,0xff);
            t.reg(1,0,repeat?0xb0:0xa0);
            auto data=t.collect(repeat?"delta_repeat":"delta_end",2048,2);
            std::cout << "Delta end/repeat " << repeat << " correlation=" << correlation(data,0) << " gain=" << rms(data,0)/rms(data,2) << std::endl;
            t.check(correlation(data,0)>0.99,"Delta-T end/repeat waveform");
            t.check(pcm_compare(data,-4,4,16).errors==0,"Delta-T end/repeat PCM");
            t.same(2,"Delta-T end/repeat status");
            t.check(rms(data,1)==0 && rms(data,3)==0,"Delta-T left pan");
            t.reg(1,0,1);t.same(2,"Delta-T reset holds playing status");
            t.reg(1,0x10,0x80);t.same(2,"Delta-T flags cleared");
        }
        t.reset();
        t.reg(1,1,1);t.reg(1,2,2);t.reg(1,4,2);t.reg(1,0,0x20);t.write(2,8);
        for(unsigned i=0;i<34;++i) t.same(3,"CPU memory read "+std::to_string(i));
        t.same(2,"CPU memory read EOS");
        t.reset();
        t.reg(1,1,1);t.reg(1,2,4);t.reg(1,4,4);t.reg(1,0,0x60);
        for(unsigned i=0;i<32;++i) t.reg(1,8,(i*7)&255);
        for(unsigned i=128;i<160;++i) t.check(t.memory[i]==t.reference.memory[i],"CPU RAM write "+std::to_string(i));
        t.same(2,"CPU memory write EOS");
        t.reset();
        t.reg(1,1,1);t.reg(1,2,0);t.reg(1,4,1);t.reg(1,12,0);t.reg(1,13,0);t.reg(1,0,0x60);
        for(unsigned i=0;i<64;++i) t.reg(1,8,(i*11)&255);
        for(unsigned i=0;i<64;++i) t.check(t.memory[i]==t.reference.memory[i],"limit-wrap RAM "+std::to_string(i));
        t.same(2,"limit wrap does not signal EOS");
        t.reset();
        t.reg(1,1,0xc0);t.reg(1,9,0xff);t.reg(1,10,0x7f);t.reg(1,11,255);t.reg(1,0x10,0);t.reg(1,0,0x80);
        t.write(2,8);
        for(unsigned byte=0;byte<64;++byte) {
            bool ready=false;
            for(unsigned retry=0;retry<1024;++retry) {
                unsigned actual=t.read(2),expected=t.reference_read;
                t.check((actual&8)==(expected&8),"CPU-fed BRDY byte="+std::to_string(byte)+" retry="+std::to_string(retry)+" rtl="+std::to_string(actual)+" mame="+std::to_string(expected));
                if(actual&8) { ready=true;break; }
                t.wait(16);
            }
            t.check(ready,"CPU-fed transfer deadline");
            t.write(3,(byte*3)&255);
        }
        t.same(2,"CPU-fed final status");
        std::ofstream result("reports/result.json");
        result << "{\"status\":\"pass\",\"checks\":" << t.checks
               << ",\"fm_correlation\":" << corr << ",\"fm_gain\":" << gain
               << ",\"scope\":\"FM/SSG/rhythm/Delta-T playback, CPU streaming and RAM transfers\"}\n";
        std::cout << "PASS " << t.checks << " checks; reports/result.json\n";
        return 0;
    } catch(const std::exception& e) {
        std::ofstream failure("reports/result.json");
        failure << "{\"status\":\"fail\",\"error\":\"" << e.what() << "\"}\n";
        std::cerr << "FAIL " << e.what() << '\n';
        return 1;
    }
}
