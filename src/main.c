#define USING_RETINA_DISPLAY 1
#define WINDOW_WIDTH 800
#define WINDOW_HEIGHT 800

#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <glad/gl.h>
#include <GLFW/glfw3.h>
#include <cglm/cglm.h>

typedef struct {
    GLfloat window_size[2];
    GLfloat cursor_pos[2];
} UserData ;

const char *FRAGMENT_SHADER_PATH = "shaders/fragment_shader.glsl";
const char *VERTEX_SHADER_PATH = "shaders/vertex_shader.glsl";

void cursor_position_callback(GLFWwindow* _window, GLdouble _x, GLdouble _y) {
    UserData *ud = (UserData*)glfwGetWindowUserPointer(_window);
    ud->cursor_pos[0] =  (float)_x;
    ud->cursor_pos[1] = (float)_y;
}

void window_size_callback(GLFWwindow* _window, int _width, int _height) {
    glViewport(0, 0, _width,  _height);
    UserData *ud = (UserData*)glfwGetWindowUserPointer(_window);
    ud->window_size[0] = (float)_width;
    ud->window_size[1] = (float)_height;
}

void process_input(GLFWwindow *_window) {
    if(glfwGetKey(_window, GLFW_KEY_ESCAPE) == GLFW_PRESS) {
        glfwSetWindowShouldClose(_window, GLFW_TRUE);
    }
}

GLint64 get_file_last_modified(const char *_path) {
    struct stat file_stat;
    if (stat(_path, &file_stat) == 0) {
        return file_stat.st_mtime;
    }
    return -1;
}

GLchar* read_shader_source(const GLchar* _path) {
    FILE* file = fopen(_path, "r");
    if (!file) {
        fprintf(stderr, "Failed to open shader file: %s\n", _path);
        return NULL;
    }
    fseek(file, 0, SEEK_END);
    GLint64 fileSize = ftell(file);
    rewind(file);
    GLchar* source = (GLchar*)malloc(fileSize + 1);
    if (!source) {
        fclose(file);
        return NULL;
    }
    fread(source, 1, fileSize, file);
    source[fileSize] = '\0';
    fclose(file);
    return source;
}

GLuint compile_shader(const GLuint _shader_type, const char *_shader_path) {
    GLint success;
    GLchar info_log[512];
    printf("COMPILING SHADER %s...", _shader_path);
    const GLchar *shader_source = read_shader_source(_shader_path);
    GLuint shader = glCreateShader(_shader_type);
    glShaderSource(shader, 1, &shader_source, NULL);
    glCompileShader(shader);
    glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
    if (!success) {
        glGetShaderInfoLog(shader, 512, NULL, info_log);
        printf("%s COMPILATION FAIL\n%s\n", _shader_path, info_log);
        return 0;
    }
    else {
        printf("SUCCESS\n");
    }
    return shader;
}

GLuint link_program(GLuint _vertex_shader, GLuint _fragment_shader) {
    printf("LINKING PROGRAM...");
    GLuint shader_program = glCreateProgram();
    glAttachShader(shader_program, _vertex_shader);
    glAttachShader(shader_program, _fragment_shader);
    glLinkProgram(shader_program);
    GLint success;
    GLchar info_log[512];
    glGetProgramiv(shader_program, GL_LINK_STATUS, &success);
    if (!success) {
        glGetProgramInfoLog(shader_program, 512, NULL, info_log);
        printf("LINKING FAIL\n%s\n", info_log);
        return 0;
    }
    else {
        printf("SUCCESS\n");
    }
    return shader_program;
}

int main() {
    glfwInit();
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
#ifdef __APPLE__
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
#endif

    GLfloat cursor_pos[2] = {0.0, 0.0};

    GLFWwindow *window = glfwCreateWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "bomboclaatt", NULL, NULL);
    if (window == NULL) {
        glfwTerminate();
        return -1;
    }
    glfwMakeContextCurrent(window);
    if (!gladLoadGL(glfwGetProcAddress)) {
        return -1;
    }
    UserData *ud = malloc(sizeof(UserData));
    glfwGetFramebufferSize(window, &ud->window_size[0], &ud->window_size[1]);
    glViewport(0, 0, ud->window_size[0], ud->window_size[1] );
    glfwSetWindowUserPointer(window, ud);

    glfwSetWindowSizeCallback(window, window_size_callback);
    glfwSetCursorPosCallback(window, cursor_position_callback);

    GLuint vertex_shader = compile_shader(GL_VERTEX_SHADER, VERTEX_SHADER_PATH);
    GLuint fragment_shader = compile_shader(GL_FRAGMENT_SHADER, FRAGMENT_SHADER_PATH);
    if (fragment_shader == 0) {
        fprintf(stderr, "Initial fragment shader compilation failed. Exiting.\n");
        glfwTerminate();
        return -1;
    }
    GLuint shader_program = link_program(vertex_shader, fragment_shader);

    GLuint VAO;
    glGenVertexArrays(1, &VAO);
    glBindVertexArray(VAO);

    GLfloat quad_vertices[] = {
        -1.0, -1.0,
        1.0, -1.0,
        -1.0, 1.0,

        1.0, -1.0,
        -1.0, 1.0,
        1.0, 1.0,
    };

    GLuint VBO;
    glGenBuffers(1, &VBO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(quad_vertices), quad_vertices, GL_STATIC_DRAW);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat), (void*) 0);
    glEnableVertexAttribArray(0);

    glUseProgram(shader_program);

    GLint cursor_loc = glGetUniformLocation(shader_program, "cursor");
    GLint resolution_loc = glGetUniformLocation(shader_program, "resolution");
    glUniform2fv(resolution_loc, 1, (float*)ud->window_size);

    GLint t_loc = glGetUniformLocation(shader_program, "t");
    GLint dt_loc = glGetUniformLocation(shader_program, "dt");
    GLfloat t_prev = 0.0f;
    GLfloat dt = 0.0f;

    int frame_count = 0;
    double fps_last_time = glfwGetTime();

    while(!glfwWindowShouldClose(window)) {
        process_input(window);

        frame_count++;
        double current_time = glfwGetTime();
        if (current_time - fps_last_time >= 0.5) {
            double fps = frame_count / (current_time - fps_last_time);
            double ms_per_frame = 1000.0 / fps;
            char window_title[128];
            snprintf(window_title, sizeof(window_title), "FPS: %.1f | ms: %.2f", fps, ms_per_frame);
            glfwSetWindowTitle(window, window_title);
            frame_count = 0;
            fps_last_time = current_time;
        }

        glUseProgram(shader_program);

        GLfloat t = glfwGetTime();
        if (t_prev != 0.0f) {
            dt = t - t_prev;
        }
        t_prev = t;
        glUniform1f(t_loc, t);
        glUniform1f(dt_loc, dt);

        GLfloat cursor_pos_norm[] = {
            ud->cursor_pos[0]/ud->window_size[0],
            ud->cursor_pos[1]/ud->window_size[1],
        };
        glUniform2fv(cursor_loc, 1, cursor_pos_norm);
        glUniform2fv(resolution_loc, 1, (float*)ud->window_size);

        GLint64 shader_last_modified = get_file_last_modified(FRAGMENT_SHADER_PATH);
        static GLint64 shader_last_modified_prev = -1;
        if (shader_last_modified_prev == -1) {
            shader_last_modified_prev = shader_last_modified;
        }
        GLint64 delta = shader_last_modified - shader_last_modified_prev;
        if (delta != 0) {
            GLuint new_fragment_shader = compile_shader(GL_FRAGMENT_SHADER, FRAGMENT_SHADER_PATH);
            if (new_fragment_shader != 0) {
                GLuint new_shader_program = link_program(vertex_shader, new_fragment_shader);
                if (new_shader_program != 0) {
                    glDeleteShader(fragment_shader);
                    glDeleteProgram(shader_program);
                    fragment_shader = new_fragment_shader;
                    shader_program = new_shader_program;
                    cursor_loc = glGetUniformLocation(shader_program, "cursor");
                    resolution_loc = glGetUniformLocation(shader_program, "resolution");
                    t_loc = glGetUniformLocation(shader_program, "t");
                    dt_loc = glGetUniformLocation(shader_program, "dt");
                } else {
                    glDeleteShader(new_fragment_shader); // Clean up failed linked shader
                }
            }
            shader_last_modified_prev = shader_last_modified;
        }

        glEnable(GL_DEPTH_TEST);
        glClearColor(0.1f, 0.1f, 0.1f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        glBindVertexArray(VAO);
        glDrawArrays(GL_TRIANGLES, 0, 6);

        glfwSwapBuffers(window);
        glfwPollEvents();
    }
    glDeleteShader(vertex_shader);
    glDeleteShader(fragment_shader);
    glfwTerminate();
    return 0;
}
