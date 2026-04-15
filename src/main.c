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
    GLfloat pos[3];
    GLfloat pitch;
    GLfloat yaw;
    GLfloat last_x;
    GLfloat last_y;
    int first_mouse; // Flag to prevent a sudden jump when the mouse first enters

    vec3 forward;
    vec3 right;
    vec3 up;
    float matrix[9];
} Camera;

typedef struct {
    GLfloat window_size[2];
    GLfloat cursor_pos[2];
    Camera camera; // Embed the camera struct here
    int mouse_captured;
} UserData;

const char *FRAGMENT_SHADER_PATH = "shaders/fragment_shader.glsl";
const char *VERTEX_SHADER_PATH = "shaders/vertex_shader.glsl";

void camera_update(Camera *cam, float xpos, float ypos) {
    if (cam->first_mouse) {
        cam->last_x = xpos;
        cam->last_y = ypos;
        cam->first_mouse = 0;
    }

    float xoffset = xpos - cam->last_x;
    float yoffset = cam->last_y - ypos; 
    cam->last_x = xpos;
    cam->last_y = ypos;

    float sensitivity = 0.002f; 
    cam->yaw += xoffset * sensitivity;
    cam->pitch += yoffset * sensitivity;

    if (cam->pitch > 1.55f) cam->pitch = 1.55f;
    if (cam->pitch < -1.55f) cam->pitch = -1.55f;

    cam->forward[0] = sin(cam->yaw) * cos(cam->pitch);
    cam->forward[1] = sin(cam->pitch);
    cam->forward[2] = -cos(cam->yaw) * cos(cam->pitch);
    glm_vec3_normalize(cam->forward);

    // 2. Calculate right and up vectors
    vec3 world_up = {0.0f, 1.0f, 0.0f};
    glm_vec3_cross(cam->forward, world_up, cam->right);
    glm_vec3_normalize(cam->right);

    glm_vec3_cross(cam->right, cam->forward, cam->up);
    glm_vec3_normalize(cam->up);

    // 3. Build the 3x3 Camera Matrix (Column-major order for OpenGL)
    cam->matrix[0] = cam->right[0];
    cam->matrix[1] = cam->right[1];
    cam->matrix[2] = cam->right[2];

    cam->matrix[3] = cam->up[0];
    cam->matrix[4] = cam->up[1];
    cam->matrix[5] = cam->up[2];

    cam->matrix[6] = cam->forward[0];
    cam->matrix[7] = cam->forward[1];
    cam->matrix[8] = cam->forward[2];
}

void cursor_position_callback(GLFWwindow* _window, GLdouble _x, GLdouble _y) {
    UserData *ud = (UserData*)glfwGetWindowUserPointer(_window);
    if (ud->mouse_captured) {
        ud->cursor_pos[0] =  (float)_x;
        ud->cursor_pos[1] = (float)_y;

        camera_update(&ud->camera, (float)_x, (float)_y);
    }
}

void window_size_callback(GLFWwindow* _window, int _width, int _height) {
    glViewport(0, 0, _width,  _height);
    UserData *ud = (UserData*)glfwGetWindowUserPointer(_window);
    ud->window_size[0] = (float)_width;
    ud->window_size[1] = (float)_height;
}

void mouse_button_callback(GLFWwindow* window, int button, int action, int mods) {
    if (button == GLFW_MOUSE_BUTTON_LEFT && action == GLFW_PRESS) {
        UserData *ud = (UserData*)glfwGetWindowUserPointer(window);
        glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);
        ud->camera.first_mouse = 1;
        ud->mouse_captured = 1;
    }
}

void process_input(GLFWwindow *_window, Camera *cam, float dt) {
    UserData *ud = (UserData*)glfwGetWindowUserPointer(_window);

    if(glfwGetKey(_window, GLFW_KEY_ESCAPE) == GLFW_PRESS) {
        glfwSetWindowShouldClose(_window, GLFW_TRUE);
    }

    if(glfwGetKey(_window, GLFW_KEY_Q) == GLFW_PRESS) {
        glfwSetInputMode(_window, GLFW_CURSOR, GLFW_CURSOR_NORMAL);
        ud->mouse_captured = 0;
    }

    if (ud->mouse_captured) {
        float speed = 5.0f * dt;
        if (glfwGetKey(_window, GLFW_KEY_LEFT_SHIFT) == GLFW_PRESS) {
            speed *= 5;
        }

        if (glfwGetKey(_window, GLFW_KEY_W) == GLFW_PRESS) {
            cam->pos[0] += cam->forward[0] * speed;
            cam->pos[1] += cam->forward[1] * speed;
            cam->pos[2] += cam->forward[2] * speed;
        }
        if (glfwGetKey(_window, GLFW_KEY_S) == GLFW_PRESS) {
            cam->pos[0] -= cam->forward[0] * speed;
            cam->pos[1] -= cam->forward[1] * speed;
            cam->pos[2] -= cam->forward[2] * speed;
        }
        if (glfwGetKey(_window, GLFW_KEY_A) == GLFW_PRESS) {
            cam->pos[0] -= cam->right[0] * speed;
            cam->pos[1] -= cam->right[1] * speed;
            cam->pos[2] -= cam->right[2] * speed;
        }
        if (glfwGetKey(_window, GLFW_KEY_D) == GLFW_PRESS) {
            cam->pos[0] += cam->right[0] * speed;
            cam->pos[1] += cam->right[1] * speed;
            cam->pos[2] += cam->right[2] * speed;
        }
        if (glfwGetKey(_window, GLFW_KEY_SPACE) == GLFW_PRESS) {
            cam->pos[1] += speed;
        }
        if (glfwGetKey(_window, GLFW_KEY_LEFT_CONTROL) == GLFW_PRESS) {
            cam->pos[1] -= speed;
        }
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
    ud->camera.pos[0] = 0.0f;
    ud->camera.pos[1] = 4.0f;
    ud->camera.pos[2] = 5.0f;
    ud->camera.pitch = 0.0f;
    ud->camera.yaw = 0.0f;
    ud->camera.first_mouse = 1; // Tell the camera it's the first time processing the mouse
    ud->mouse_captured = 1;

    glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);

    glfwGetFramebufferSize(window, &ud->window_size[0], &ud->window_size[1]);
    glViewport(0, 0, ud->window_size[0], ud->window_size[1] );
    glfwSetWindowUserPointer(window, ud);

    glfwSetWindowSizeCallback(window, window_size_callback);
    glfwSetCursorPosCallback(window, cursor_position_callback);
    glfwSetMouseButtonCallback(window, mouse_button_callback);

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

    GLint cursor_loc = glGetUniformLocation(shader_program, "u_cursor");
    GLint resolution_loc = glGetUniformLocation(shader_program, "u_resolution");
    glUniform2fv(resolution_loc, 1, (float*)ud->window_size);

    GLint t_loc = glGetUniformLocation(shader_program, "u_t");
    GLint dt_loc = glGetUniformLocation(shader_program, "u_dt");
    GLfloat t_prev = 0.0f;
    GLfloat dt = 0.0f;

    int frame_count = 0;
    double fps_last_time = glfwGetTime();

    while(!glfwWindowShouldClose(window)) {
        process_input(window, &ud->camera, dt);

        GLint ro_loc = glGetUniformLocation(shader_program, "u_ro");
        glUniform3fv(ro_loc, 1, (float*)ud->camera.pos);

        GLint cam_mat_loc = glGetUniformLocation(shader_program, "u_cam_matrix");
        glUniformMatrix3fv(cam_mat_loc, 1, GL_FALSE, ud->camera.matrix);

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
                    cursor_loc = glGetUniformLocation(shader_program, "u_cursor");
                    resolution_loc = glGetUniformLocation(shader_program, "u_resolution");
                    t_loc = glGetUniformLocation(shader_program, "u_t");
                    dt_loc = glGetUniformLocation(shader_program, "u_dt");
                } else {
                    glDeleteShader(new_fragment_shader);
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
