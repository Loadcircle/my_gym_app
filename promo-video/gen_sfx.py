import wave, struct, math, os

SR = 44100

def write_wav(path, samples):
    with wave.open(path, 'w') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SR)
        for s in samples:
            clamped = max(-1.0, min(1.0, s))
            f.writeframes(struct.pack('<h', int(clamped * 32767)))

os.makedirs('assets', exist_ok=True)

# ── WHOOSH (zoom-through transitions) ──
# Chirp from 600→120 Hz, 0.28s, smooth envelope
dur = 0.28
samples = []
for i in range(int(SR * dur)):
    t = i / SR
    env = math.sin(t / dur * math.pi) ** 0.7
    freq = 600 - (480 * (t / dur) ** 1.4)
    s = env * math.sin(2 * math.pi * freq * t) * 0.30
    samples.append(s)
write_wav('assets/sfx_whoosh.wav', samples)
print("sfx_whoosh.wav written")

# ── SLAM (push-left transitions) ──
# Low thud: 80 Hz burst with fast attack, quick decay
dur = 0.20
samples = []
for i in range(int(SR * dur)):
    t = i / SR
    env = math.exp(-t * 18) * (1 - math.exp(-t * 300))
    freq = 80 - (30 * t / dur)
    noise = math.sin(2 * math.pi * 440 * t) * 0.08 * math.exp(-t * 50)
    s = env * math.sin(2 * math.pi * freq * t) * 0.45 + noise
    samples.append(s)
write_wav('assets/sfx_slam.wav', samples)
print("sfx_slam.wav written")

print("Done.")
