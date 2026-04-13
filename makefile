CC := gcc
SRC_DIR := src
INC_DIR := inc
OBJ_DIR := obj
BIN_DIR := bin
OUT := $(BIN_DIR)/out

GLFW_DIR :=/opt/homebrew/Cellar/glfw/3.4
GLFW_HEADERS := $(GLFW_DIR)/include
GLFW_LIB := $(GLFW_DIR)/lib

SOURCES := $(wildcard $(SRC_DIR)/*.c)
OBJECTS := $(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/%.o,$(SOURCES))
CFLAGS := -I$(INC_DIR) $(shell pkg-config --cflags glfw3) $(shell pkg-config --cflags cglm) -Wall -Wextra
LDFLAGS := $(shell pkg-config --libs glfw3) $(shell pkg-config --libs cglm) -framework OpenGl -framework Cocoa -framework IOKit -framework CoreVideo

.PHONY: all clean

all: $(OUT)

$(OUT): $(OBJECTS) | $(BIN_DIR)
	$(CC) $^ -o $@ $(LDFLAGS)

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c | $(OBJ_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(BIN_DIR) $(OBJ_DIR):
	mkdir -p $@

clean:
	rm -f $(BIN_DIR)/* $(OBJ_DIR)/*

