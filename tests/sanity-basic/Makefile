all: bin/write bin/read

bin/write: write.cu
	mkdir -p bin
	nvcc -o bin/write write.cu -ldragon

bin/read: read.cu
	mkdir -p bin
	nvcc -o bin/read read.cu -ldragon

bin/read-direct: read-direct.cu
	mkdir -p bin
	nvcc -o bin/read-direct read-direct.cu -ldragon

clean:
	rm -rf bin

