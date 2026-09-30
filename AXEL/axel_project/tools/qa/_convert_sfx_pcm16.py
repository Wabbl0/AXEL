from pathlib import Path
from scipy.io import wavfile
import numpy as np
import struct

sfx = Path(__file__).resolve().parents[2] / "assets" / "audio" / "sfx"


def parse_wav(path: Path):
	data = path.read_bytes()
	assert data[0:4] == b"RIFF" and data[8:12] == b"WAVE"
	pos = 12
	fmt = None
	audio = None
	while pos + 8 <= len(data):
		chunk_id = data[pos : pos + 4]
		chunk_size = struct.unpack_from("<I", data, pos + 4)[0]
		chunk_data = data[pos + 8 : pos + 8 + chunk_size]
		if chunk_id == b"fmt ":
			fmt = chunk_data
		elif chunk_id == b"data":
			audio = chunk_data
		pos += 8 + chunk_size
		if chunk_size % 2 == 1:
			pos += 1
	if fmt is None or audio is None:
		raise RuntimeError(f"bad wav {path.name}")
	audio_format = struct.unpack_from("<H", fmt, 0)[0]
	channels = struct.unpack_from("<H", fmt, 2)[0]
	rate = struct.unpack_from("<I", fmt, 4)[0]
	bits = struct.unpack_from("<H", fmt, 14)[0]
	if audio_format == 0xFFFE and len(fmt) >= 40:
		audio_format = struct.unpack_from("<H", fmt, 24)[0]
	print(f"{path.name}: format={audio_format} ch={channels} rate={rate} bits={bits} data={len(audio)}")
	if bits == 16:
		samples = np.frombuffer(audio, dtype="<i2")
	elif bits == 24:
		raw = np.frombuffer(audio, dtype=np.uint8)
		if len(raw) % 3 != 0:
			raw = raw[: len(raw) - (len(raw) % 3)]
		b0 = raw[0::3].astype(np.int32)
		b1 = raw[1::3].astype(np.int32)
		b2 = raw[2::3].astype(np.int32)
		samples = b0 | (b1 << 8) | (b2 << 16)
		samples = np.where(samples >= 0x800000, samples - 0x1000000, samples)
		samples = (samples >> 8).astype(np.int16)
	elif bits == 32 and audio_format == 3:
		samples = np.frombuffer(audio, dtype="<f4")
		samples = np.clip(samples, -1.0, 1.0)
		samples = (samples * 32767.0).astype(np.int16)
	else:
		raise RuntimeError(f"unsupported bits={bits} format={audio_format}")
	if channels > 1:
		samples = samples.reshape(-1, channels)
	return rate, samples


def main() -> None:
	for wav in sorted(sfx.glob("*.wav")):
		rate, samples = parse_wav(wav)
		tmp = wav.with_suffix(".pcm16.tmp.wav")
		wavfile.write(str(tmp), rate, samples)
		tmp.replace(wav)
		print(f"wrote PCM16 {wav.name} shape={samples.shape} rate={rate}")


if __name__ == "__main__":
	main()
