all: read-bw

read-bw: read-bw.cu
	nvcc -o read-bw read-bw.cu -ldragon

clean:
	rm -rf *.o read-bw

