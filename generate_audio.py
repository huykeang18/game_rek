import math
import struct
import wave
import os

SAMPLE_RATE = 22050

def write_wav(filepath, samples, sample_rate=SAMPLE_RATE):
    with wave.open(filepath, 'w') as wf:
        wf.setnchannels(1)  # Mono
        wf.setsampwidth(2)  # 16-bit
        wf.setframerate(sample_rate)
        # Clip and pack
        packed = bytearray()
        for s in samples:
            val = max(-32767, min(32767, int(s * 32767.0)))
            packed.extend(struct.pack('<h', val))
        wf.writeframes(packed)
    print(f"Generated {filepath} ({len(samples)/sample_rate:.2f}s, {len(packed)} bytes)")

def wood_bar(freq, duration, sample_rate=SAMPLE_RATE):
    """Simulates a wooden bar (roneat/marimba) hit."""
    num_samples = int(duration * sample_rate)
    samples = [0.0] * num_samples
    for i in range(num_samples):
        t = i / sample_rate
        # Fast attack, exponential decay
        env = math.exp(-t * 9.0)
        # Harmonics for wood (non-integer ratios)
        h1 = math.sin(2 * math.pi * freq * t)
        h2 = 0.4 * math.sin(2 * math.pi * freq * 2.76 * t) * math.exp(-t * 18.0)
        h3 = 0.2 * math.sin(2 * math.pi * freq * 5.4 * t) * math.exp(-t * 28.0)
        # Soft mallet tap noise at onset
        click = (math.sin(2 * math.pi * 1200 * t) if t < 0.008 else 0.0) * math.exp(-t * 300)
        samples[i] = (h1 + h2 + h3 + click * 0.3) * env
    return samples

def bell_tone(freq, duration, sample_rate=SAMPLE_RATE):
    """Simulates a singing bowl / temple bell tone."""
    num_samples = int(duration * sample_rate)
    samples = [0.0] * num_samples
    for i in range(num_samples):
        t = i / sample_rate
        env = math.exp(-t * 1.5)
        # Rich metallic partials
        h1 = math.sin(2 * math.pi * freq * t)
        h2 = 0.5 * math.sin(2 * math.pi * freq * 1.52 * t) * math.exp(-t * 2.0)
        h3 = 0.3 * math.sin(2 * math.pi * freq * 2.8 * t) * math.exp(-t * 3.0)
        samples[i] = (h1 + h2 + h3) * env * 0.6
    return samples

def mix_into(target, source, start_index, gain=1.0):
    for i in range(len(source)):
        idx = start_index + i
        if idx < len(target):
            target[idx] += source[i] * gain

def generate_roneat_melody(out_path):
    # A 12-second peaceful Khmer pentatonic loop: D4, F4, G4, A4, C5, D5
    notes = {
        'D4': 293.66,
        'F4': 349.23,
        'G4': 392.00,
        'A4': 440.00,
        'C5': 523.25,
        'D5': 587.33,
        'F5': 698.46,
    }
    duration = 12.0
    total_samples = int(duration * SAMPLE_RATE)
    buffer = [0.0] * total_samples

    # Rhythmic peaceful sequence
    melody = [
        ('D4', 0.0, 1.2), ('G4', 0.5, 1.0), ('A4', 1.0, 1.2), ('C5', 1.5, 1.5),
        ('D5', 2.2, 1.5), ('C5', 3.0, 1.0), ('A4', 3.5, 1.2), ('G4', 4.0, 1.8),
        ('F4', 5.0, 1.2), ('G4', 5.5, 1.0), ('A4', 6.0, 1.5), ('D4', 7.0, 1.8),
        ('A4', 8.0, 1.0), ('C5', 8.5, 1.0), ('D5', 9.0, 1.5), ('C5', 10.0, 1.2),
        ('A4', 10.5, 1.0), ('G4', 11.0, 1.5),
    ]

    for note, start_t, note_dur in melody:
        freq = notes[note]
        samples = wood_bar(freq, note_dur)
        mix_into(buffer, samples, int(start_t * SAMPLE_RATE), gain=0.6)

    # Gentle ambient drone under melody (D3, A3)
    for i in range(total_samples):
        t = i / SAMPLE_RATE
        drone = (math.sin(2 * math.pi * 146.83 * t) * 0.08 +
                 math.sin(2 * math.pi * 220.00 * t) * 0.05)
        # Fade in and fade out at edges for seamless loop
        fade = min(1.0, t / 0.5) * min(1.0, (duration - t) / 0.5)
        buffer[i] = (buffer[i] + drone) * fade

    # Normalize
    max_val = max(abs(s) for s in buffer) or 1.0
    buffer = [s / max_val * 0.85 for s in buffer]
    write_wav(out_path, buffer)

def generate_angkor_ambient(out_path):
    # Atmospheric 10-second singing bowl meditation loop
    duration = 10.0
    total_samples = int(duration * SAMPLE_RATE)
    buffer = [0.0] * total_samples

    # Bell chimes at intervals
    chimes = [
        (220.0, 0.2, 5.0), # A3
        (329.63, 2.5, 4.5), # E4
        (440.0, 5.0, 4.5), # A4
        (293.66, 7.5, 4.0), # D4
    ]
    for freq, start_t, dur in chimes:
        samples = bell_tone(freq, dur)
        mix_into(buffer, samples, int(start_t * SAMPLE_RATE), gain=0.55)

    # Low singing drone
    for i in range(total_samples):
        t = i / SAMPLE_RATE
        drone = math.sin(2 * math.pi * 110.0 * t) * 0.12 + math.sin(2 * math.pi * 165.0 * t) * 0.08
        fade = min(1.0, t / 0.8) * min(1.0, (duration - t) / 0.8)
        buffer[i] = (buffer[i] + drone) * fade

    max_val = max(abs(s) for s in buffer) or 1.0
    buffer = [s / max_val * 0.85 for s in buffer]
    write_wav(out_path, buffer)

def generate_peaceful_bamboo(out_path):
    # 8-second light bamboo wind chime loop
    duration = 8.0
    total_samples = int(duration * SAMPLE_RATE)
    buffer = [0.0] * total_samples

    taps = [
        (523.25, 0.1, 1.2), (659.25, 0.6, 1.0), (783.99, 1.2, 1.4),
        (587.33, 2.0, 1.2), (523.25, 2.7, 1.0), (880.00, 3.4, 1.5),
        (659.25, 4.2, 1.2), (587.33, 5.0, 1.2), (783.99, 5.8, 1.4),
        (659.25, 6.7, 1.2),
    ]
    for freq, start_t, dur in taps:
        samples = wood_bar(freq, dur)
        mix_into(buffer, samples, int(start_t * SAMPLE_RATE), gain=0.5)

    for i in range(total_samples):
        t = i / SAMPLE_RATE
        fade = min(1.0, t / 0.4) * min(1.0, (duration - t) / 0.4)
        buffer[i] = buffer[i] * fade

    max_val = max(abs(s) for s in buffer) or 1.0
    buffer = [s / max_val * 0.85 for s in buffer]
    write_wav(out_path, buffer)

def generate_move_sfx(out_path):
    # 0.12s crisp wooden piece clack
    duration = 0.12
    num_samples = int(duration * SAMPLE_RATE)
    buffer = [0.0] * num_samples
    for i in range(num_samples):
        t = i / duration
        # Pitch descends quickly: 550Hz -> 180Hz
        freq = 550.0 - 370.0 * (t ** 0.5)
        phase = 2 * math.pi * freq * (i / SAMPLE_RATE)
        env = math.exp(-t * 14.0)
        # Add slight click on impact
        click = (math.sin(2 * math.pi * 1800 * (i / SAMPLE_RATE)) if i < 150 else 0.0)
        buffer[i] = (math.sin(phase) + 0.4 * click) * env
    max_val = max(abs(s) for s in buffer) or 1.0
    buffer = [s / max_val * 0.9 for s in buffer]
    write_wav(out_path, buffer)

def generate_capture_sfx(out_path):
    # 0.7s resonant traditional gong / strike chord for Rek capture
    duration = 0.7
    num_samples = int(duration * SAMPLE_RATE)
    buffer = [0.0] * num_samples
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 5.0)
        tone1 = math.sin(2 * math.pi * 330.0 * t)
        tone2 = math.sin(2 * math.pi * 495.0 * t) * 0.7
        tone3 = math.sin(2 * math.pi * 990.0 * t) * 0.3 * math.exp(-t * 12.0)
        buffer[i] = (tone1 + tone2 + tone3) * env
    max_val = max(abs(s) for s in buffer) or 1.0
    buffer = [s / max_val * 0.9 for s in buffer]
    write_wav(out_path, buffer)

def generate_win_sfx(out_path):
    # 1.4s ascending victory fanfare
    notes = [
        (392.00, 0.0, 0.25),  # G4
        (523.25, 0.25, 0.25), # C5
        (659.25, 0.50, 0.25), # E5
        (783.99, 0.75, 0.65), # G5
    ]
    duration = 1.4
    total_samples = int(duration * SAMPLE_RATE)
    buffer = [0.0] * total_samples
    for freq, start_t, dur in notes:
        ns = int(dur * SAMPLE_RATE)
        for i in range(ns):
            t = i / SAMPLE_RATE
            env = math.exp(-t * 3.5)
            s = (math.sin(2 * math.pi * freq * t) + 0.3 * math.sin(4 * math.pi * freq * t)) * env
            idx = int(start_t * SAMPLE_RATE) + i
            if idx < total_samples:
                buffer[idx] += s * 0.5
    max_val = max(abs(s) for s in buffer) or 1.0
    buffer = [s / max_val * 0.9 for s in buffer]
    write_wav(out_path, buffer)

def generate_click_sfx(out_path):
    # 0.04s subtle UI button tap
    duration = 0.04
    num_samples = int(duration * SAMPLE_RATE)
    buffer = [0.0] * num_samples
    for i in range(num_samples):
        t = i / duration
        freq = 900.0 - 500.0 * t
        env = math.exp(-t * 16.0)
        buffer[i] = math.sin(2 * math.pi * freq * (i / SAMPLE_RATE)) * env * 0.6
    write_wav(out_path, buffer)

def main():
    out_dir = os.path.join(os.path.dirname(__file__), "assets", "audio")
    os.makedirs(out_dir, exist_ok=True)
    generate_roneat_melody(os.path.join(out_dir, "roneat_melody.wav"))
    generate_angkor_ambient(os.path.join(out_dir, "angkor_ambient.wav"))
    generate_peaceful_bamboo(os.path.join(out_dir, "peaceful_bamboo.wav"))
    generate_move_sfx(os.path.join(out_dir, "move.wav"))
    generate_capture_sfx(os.path.join(out_dir, "capture.wav"))
    generate_win_sfx(os.path.join(out_dir, "win.wav"))
    generate_click_sfx(os.path.join(out_dir, "click.wav"))
    print("All audio files generated successfully!")

if __name__ == "__main__":
    main()
