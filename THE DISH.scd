
///////    Buffers     ///////
(
~path = PathName.new(thisProcess.nowExecutingPath).parentPath ++ "audio/";

~doorslam = Buffer.read (s, ~path ++ "doorclosing.wav");
~bagzip = Buffer.read (s, ~path ++  "bagzip.wav");
~fan = Buffer.read (s, ~path ++  "fan.wav");
~buffer = Buffer.read(s, ~path ++  "bagzip.wav");
~buffer2 = Buffer.read(s, ~path ++  "switches (1).wav");
~buffer3 = Buffer.read(s, ~path ++  "keyboard.wav");
)

 ///////    SynthDefs     ///////

(
(
SynthDef ( \drum, { | bufnum, amp = 0.5, sus = 1 |
    var sound = PlayBuf.ar ( 2, bufnum, loop: 0, doneAction: 2 );
    sound = LPF.ar ( sound, 250 );
    sound = sound * amp;
    Out.ar ( 0, sound!2 );
}).add;
);

(
SynthDef ( \zipper, {
    | bufnum, rate = 4 |
    var sound = PlayBuf.ar ( 1, bufnum, BufRateScale.kr ( bufnum ) * rate, loop: 1 ) * 0.5;
    var chaos = Dust.ar(10) * 0.1;
    Out.ar( 0, sound + chaos );
}).add;
);


(
SynthDef(\electroNotes, {
    | freq = 440, amp = 0.1, sus = 1 |
    var env = EnvGen.kr(Env.perc(0.01, sus), doneAction: 2);
    var sig = Saw.ar(freq) * env;
    var filter = LPF.ar(sig, 1000);
    var reverb = FreeVerb.ar(filter, mix: 0.3, room: 0.7, damp: 0.5);
	sig = sig * amp;
    Out.ar(0, reverb);
}).add;
)


 ///////    Pre-requisites     ///////

~tempo = TempoClock.new(120); // 120 BPM

      ///////    Ndefs     ///////


(
Ndef ( \drum, Pbind (
    \instrument, \drum,
    \bufnum, ~doorslam,
    \amp, 1,
	\dur, Pseq ( [ 0, 1 ], inf ),
    \sus, 1
    )
).play ( ~tempo );
)

(
Ndef(\zipper, Pbind(
    \instrument, \zipper,
    \bufnum, ~bagzip,
    \amp, 0.5,
    \sus, 1,
    \rate, 10,
	\rate, rrand(-12, 12).midiratio,
    \dur, Pseq([0.5, 05], inf)
)).play ( ~tempo );
)

(
Ndef ( \notes,
    Pbind (
        \instrument, \electroNotes,
        \freq, Pseq ( [ 261.63, 293.66, 329.63, 293.66,
261.63, 293.66, 329.63, 293.66,
261.63, 261.63, 293.66, 261.63,
293.66, 329.63, 349.23, 329.63], inf ),

        \amp, Pwhite ( 0.1, 0.3, inf ),
        \sus, 0.1,
		\rel, 0.1,
		\drive, Pwhite(0.1, 1.0, inf),
        \dur, Pseq ( [ 0.12, 0.12, 0.24, 0.24,
			0.24, 0.12, 0.12, 0.12, 0.12, 0.12,
			0.12, 0.12, 0.12 ], inf )
    )
).play ( ~tempo );
)

(
Ndef(\doorslam, {
    var sound, dynKlankEffect, smoothedSignal, reverb;

    sound = PlayBuf.ar(2, ~doorslam, BufRateScale.kr(~doorslam), loop: 1);

    dynKlankEffect = DynKlank.ar(
        `[[CuspN.ar(1).range(100, 300).lag(1), HenonL.ar(5).range(200, 500).lag(4)], nil, [2, 4]],
        Impulse.ar(GbmanN.ar(100).range(1, 10).lag(2), 0, 1) ! 2
    );

    smoothedSignal = sound * dynKlankEffect;

    smoothedSignal = LPF.ar(smoothedSignal, 1000);

    reverb = FreeVerb.ar(smoothedSignal, mix: 1, room: 1, damp: 0.5);

    Out.ar(0, reverb);
}).play;
)

(
Ndef(\beats, {
    var sound = PlayBuf.ar(1, ~buffer, BufRateScale.kr(~buffer) * 10.midiratio, loop: 1) * 0.5;
    var chaos = Dust.ar(10) * 0.1; //
    sound + chaos;
	Out.ar(0,sound);
}).play;
)


(
~setFastRate = { |rate = 10|
    Ndef(\beats).source = {
        var sound = PlayBuf.ar(1, ~buffer, BufRateScale.kr(~buffer) * rate, loop: 1) * 0.5;
        var chaos = Dust.ar(10) * 0.1;
        sound + chaos;
    };
};

~setFastRate.(7);
)


(
Ndef(\switches, {
    var sound, chaosEffect, modulatedBuffer, smoothedSignal, reverb, freqShift, combDelay;

    sound = PlayBuf.ar(1, ~buffer2, BufRateScale.kr(~buffer2) * LFNoise1.kr(0.2).range(0.9, 1.1), loop: 1);

    chaosEffect = DynKlank.ar(
        `[[CuspN.ar(sound).range(50, 300).lag(2), HenonL.ar(sound).range(150, 700).lag(3)], nil, [2, 4]],
        Impulse.ar(GbmanN.ar(sound).range(0.5, 4).lag(2), 0, 1) ! 2
    );

    modulatedBuffer = Ringz.ar(sound * chaosEffect, [800, 200], 0.2) * FreqShift.ar(sound, LFNoise1.kr(0.5).range(-20, 20));

    combDelay = CombL.ar(modulatedBuffer, 0.5, LFNoise2.kr(0.3).range(0.1, 0.5), 4);

    smoothedSignal = LPF.ar(combDelay, 800);

    reverb = FreeVerb.ar(smoothedSignal, mix: 0.7, room: 0.8, damp: 0.5);

    Out.ar(0, reverb);
}).play;
)

(
Ndef(\whaleSound, {
    var sound = PlayBuf.ar(1, ~buffer2, BufRateScale.kr(~buffer2) * 10.midiratio, loop: 1) ;
    var reverb = FreeVerb.ar(sound, mix: 0.9, room: 0.95, damp: 0.7);
    reverb;
	Out.ar(0,reverb);
}).play;
)


(
Routine({
    var beatDur = 5;

    Ndef(\drum).play;
    beatDur.wait; // Wait for 5 seconds

    Ndef(\zipper).play;
    beatDur.wait;

    Ndef(\switches).play;
    beatDur.wait;

    Ndef(\whaleSound).play;
    beatDur.wait;

    Ndef(\doorslam).play;
    beatDur.wait;

    Ndef(\beats).play;
    beatDur.wait;

    Ndef(\notes).play;
}).play;
)













