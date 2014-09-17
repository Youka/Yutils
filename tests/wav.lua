local Yutils = dofile("../src/Yutils.lua")

local wav = Yutils.decode.create_wav_reader("test.wav")
print("File size: " .. wav.file_size())
print("Channels number: " .. wav.channels_number())
print("Sample rate: " .. wav.sample_rate())
print("Byte rate: " .. wav.byte_rate())
print("Block align: " .. wav.block_align())
print("Bits per sample: " .. wav.bits_per_sample())
print("Samples per channel: " .. wav.samples_per_channel())
print("Minimal & maximal amplitude: ", wav.min_max_amplitude())
print("Sample at 120 milliseconds: " .. wav.sample_from_ms(120))
print("Milliseconds at sample 87: " .. wav.ms_from_sample(87))
print("Position set to sample " .. wav.position(2))
print("Read 100 samples:\n" .. Yutils.table.tostring(wav.samples(100)))

wav.position(0)
local samples = wav.samples(4096)[1]
for i=1, samples.n do
	samples[i] = samples[i] / math.abs(wav.min_max_amplitude())
end
print("Frequencies of some samples from channel 1:\n" .. Yutils.table.tostring(Yutils.decode.create_frequency_analyzer(samples, wav.sample_rate()).frequencies()))