PROJ=vips
BUILD_DIR=build
SRC_DIR=src
all: build flash

flash: build
	openocd -f numato_oocd.cfg -c "transport select jtag; init; svf $(BUILD_DIR)/$(PROJ).svf; exit"

build: dir $(PROJ).svf
# This feels sucky but i don't know how to do it better...
dir: 
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf build .build dependencies $(PROJ).f ./src/*.sv ./src/*.sv.map

.PHONY: flash build dir all clean

%.sv: ./$(SRC_DIR)/${PROJ}.veryl
	veryl build

%.v: ./$(SRC_DIR)/%.sv
	sv2v $(shell cat $(PROJ).f) ./oscillator.sv > $(BUILD_DIR)/$@

%.json: %.v
	yosys -p "read_verilog $(BUILD_DIR)/$<; hierarchy -check -top vips_Vips; synth_ecp5 -json $(BUILD_DIR)/$@"

%.cfg: %.json
	nextpnr-ecp5 --json $(BUILD_DIR)/$< --textcfg $(BUILD_DIR)/$@ --45k --package CABGA256 --lpf numato.lpf

%.svf: %.cfg
	ecppack --svf $(BUILD_DIR)/$@ --input $(BUILD_DIR)/$< 