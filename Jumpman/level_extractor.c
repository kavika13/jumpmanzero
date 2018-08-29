// TODO: Remove CRT dependencies?
#include <inttypes.h>
#include <math.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

const int kERROR_NO_ERROR = 0;
const int kERROR_INVALID_ARUGMENTS = 1;
const int kERROR_INPUT_FILE_MISSING = 2;
const int kERROR_ALLOCATION_FAILED = 3;
const int kERROR_INVALID_LEVEL_DATA = 4;

#define kLEVEL_DATA_ENTRY_RESOURCE_REFERENCE 'R'
#define kLEVEL_DATA_ENTRY_QUAD 'A'
#define kLEVEL_DATA_ENTRY_LADDER 'L'
#define kLEVEL_DATA_ENTRY_WALL 'W'
#define kLEVEL_DATA_ENTRY_VINE 'V'
#define kLEVEL_DATA_ENTRY_DONUT 'D'
#define kLEVEL_DATA_ENTRY_PLATFORM 'P'

uint16_t extract_uint16(const unsigned char* data) {
    float result = data[0] * 256.0f +
        data[1];
    return (int16_t)result;
}

int32_t extract_int32(const unsigned char* data) {
    float result = (data[0] & 127) * 256.0f * 256.0f * 256.0f +
        data[1] * 256.0f * 256.0f +
        data[2] * 256.0f +
        data[3];

    if(data[0] & 128) {
        return (int32_t)(result) * -1;
    } else {
        return (int32_t)(result);
    }
}

const char* extract_bool_str(bool value) {
    return value ? "True" : "False";
}

int print_level(const unsigned char* level_data, size_t level_data_byte_count) {
    size_t current_byte_index = 0;

    while(current_byte_index < level_data_byte_count) {
        if(level_data[current_byte_index + 1] != 0) {
            fprintf(stderr, "Level data entry missing padding byte after entry type id at byte %zu\n", current_byte_index + 1);
            return kERROR_INVALID_LEVEL_DATA;
        }

        switch(level_data[current_byte_index]) {
            case kLEVEL_DATA_ENTRY_RESOURCE_REFERENCE: {
                current_byte_index += 2;
                printf("R");

                char resource_name[31] = { '\0' };
                for(int i = 0; i < 30; ++i) {
                    resource_name[i] = level_data[current_byte_index + i];
                }
                current_byte_index += 30;
                printf(" %s", resource_name);

                uint16_t resource_type = extract_uint16(&level_data[current_byte_index + 0]);
                uint16_t resource_argument_1 = extract_uint16(&level_data[current_byte_index + 2]);
                uint16_t resource_argument_2 = extract_uint16(&level_data[current_byte_index + 4]);

                current_byte_index += 8;
                printf(" %u %u %u\n", resource_type, resource_argument_1, resource_argument_2);
                break;
            }
            case kLEVEL_DATA_ENTRY_QUAD: {
                current_byte_index += 2;
                printf("O");

                current_byte_index += 8;  // Just empty space in this type

                uint16_t texture_id = extract_uint16(&level_data[current_byte_index + 0]);
                // uint16_t x_offset = extract_uint16(&level_data[current_byte_index + 2]);  // Unused
                // uint16_t y_offset = extract_uint16(&level_data[current_byte_index + 4]);  // Unused
                uint16_t object_id = extract_uint16(&level_data[current_byte_index + 6]);
                current_byte_index += 20;
                printf(" True True True True True False 0 0 0 0 0 0 0 0 0 %u 0 0 0 0 ARBITRARY", object_id);

                uint16_t component_count = extract_uint16(&level_data[current_byte_index]) / 4;
                current_byte_index += 2;

                #define expected_vertex_count 6
                #define vertex_component_count 9
                const uint16_t expected_component_count = expected_vertex_count * vertex_component_count;

                if(component_count != expected_component_count) {
                    fprintf(stderr, "Invalid count for Quad level data entry - expected: %u, actual: %u\n",
                        expected_component_count, component_count);
                    return kERROR_INVALID_LEVEL_DATA;
                }

                float vertex_data[expected_vertex_count][vertex_component_count];

                for(size_t v = 0; v < expected_vertex_count; ++v) {
                    for(size_t i = 0; i < vertex_component_count; ++i) {
                        size_t current_byte_offset = (v * vertex_component_count + i) * 4;
                        // vertex_data[v][i] = extract_int32(&level_data[current_byte_index + current_byte_offset]) / 256.0f;
                        vertex_data[v][i] = extract_int32(&level_data[current_byte_index + current_byte_offset]) / 256.0f / 256.0f;  // Note: Only untitled.dat seems to be this far off
                    }
                }

                #undef vertex_component_count
                #undef expected_vertex_count

                current_byte_index += component_count * 4;
                printf(" %g %g %g %g %g", vertex_data[0][7], vertex_data[0][8], vertex_data[0][0], vertex_data[0][1], vertex_data[0][2]);
                printf(" %g %g %g %g %g", vertex_data[1][7], vertex_data[1][8], vertex_data[1][0], vertex_data[1][1], vertex_data[1][2]);
                printf(" %g %g %g %g %g", vertex_data[2][7], vertex_data[2][8], vertex_data[2][0], vertex_data[2][1], vertex_data[2][2]);
                printf(" %g %g %g %g %g", vertex_data[4][7], vertex_data[4][8], vertex_data[4][0], vertex_data[4][1], vertex_data[4][2]);
                printf(" 0 0 0 0 0");
                printf(" 0 0 0 0 0");
                printf(" 0 0 0 0 0");
                printf(" 0 0 0 0 0");

                float front_z = min(min(min(vertex_data[0][2], vertex_data[1][2]), vertex_data[2][2]), vertex_data[4][2]);  // TODO: See if this works with level2
                printf(" %g %u %u\n", front_z, 1, texture_id);
                break;
            }
            case kLEVEL_DATA_ENTRY_LADDER: {
                current_byte_index += 2;
                printf("O");

                current_byte_index += 8;  // Skipping over subroutine name

                uint16_t origin_x = extract_uint16(&level_data[current_byte_index + 0]);
                uint16_t top_y = extract_uint16(&level_data[current_byte_index + 2]);
                uint16_t bottom_y = extract_uint16(&level_data[current_byte_index + 4]);
                uint16_t front_z = extract_uint16(&level_data[current_byte_index + 6]);
                // uint16_t back_z = extract_uint16(&level_data[current_byte_index + 8]);  // equals front_z here when compiled
                uint16_t object_id = extract_uint16(&level_data[current_byte_index + 10]);
                uint16_t texture_id = extract_uint16(&level_data[current_byte_index + 12]);
                current_byte_index += 20;

                uint16_t component_count = extract_uint16(&level_data[current_byte_index]) / 4;
                current_byte_index += 2;

                current_byte_index += component_count * 4;

                // OK to hard code front and back vis for ladders
                // Can manually edit the file to fix it if necessary
                printf(" True True True True True False");
                printf(" 0 0 0 0 0 0 0 0 0 %u 0 0 0 0 LADDER", object_id);

                // Giving up on UVs because the data gets thrown away in compile
                // Also only writing out two vertices, because the other 6 don't get used by the compiler
                printf(" 0 0 %u %u 0", origin_x, top_y);
                printf(" 0 0 0 %u 0", bottom_y);
                printf(" 0 0 0 0 0");
                printf(" 0 0 0 0 0");
                printf(" 0 0 0 0 0");
                printf(" 0 0 0 0 0");
                printf(" 0 0 0 0 0");
                printf(" 0 0 0 0 0");

                printf(" %u %u %u\n", front_z, front_z + 1, texture_id);
                break;
            }
            case kLEVEL_DATA_ENTRY_WALL: {
                current_byte_index += 2;
                printf("O");

                current_byte_index += 8;  // Skipping over subroutine name

                uint16_t top_left_x = extract_uint16(&level_data[current_byte_index + 0]);
                uint16_t top_left_y = extract_uint16(&level_data[current_byte_index + 2]);
                uint16_t top_right_x = extract_uint16(&level_data[current_byte_index + 4]);
                uint16_t top_right_y = extract_uint16(&level_data[current_byte_index + 6]);
                uint16_t bottom_left_x = extract_uint16(&level_data[current_byte_index + 8]);
                uint16_t bottom_left_y = extract_uint16(&level_data[current_byte_index + 10]);
                uint16_t bottom_right_x = extract_uint16(&level_data[current_byte_index + 12]);
                uint16_t bottom_right_y = extract_uint16(&level_data[current_byte_index + 14]);
                uint16_t object_id = extract_uint16(&level_data[current_byte_index + 16]);
                uint16_t texture_id = extract_uint16(&level_data[current_byte_index + 18]);
                current_byte_index += 20;

                uint16_t component_count = extract_uint16(&level_data[current_byte_index]) / 4;
                current_byte_index += 2;

                #define vertex_component_count 9
                const uint16_t vertex_count = component_count / vertex_component_count;
                const uint16_t expected_component_count = vertex_count * vertex_component_count;

                if(component_count != expected_component_count) {  // Validating it is divisible by vertex_component_count
                    fprintf(stderr, "Invalid count for Platform level data entry - expected: %u, actual: %u\n",
                        expected_component_count, component_count);
                    return kERROR_INVALID_LEVEL_DATA;
                }

                #define max_face_count 6
                #define vertices_per_face 6
                float vertex_data[max_face_count * vertices_per_face][vertex_component_count];

                #undef max_face_count

                for(size_t v = 0; v < vertex_count; ++v) {
                    for(size_t i = 0; i < vertex_component_count; ++i) {
                        size_t current_byte_offset = (v * vertex_component_count + i) * 4;
                        // vertex_data[v][i] = extract_int32(&level_data[current_byte_index + current_byte_offset]) / 256.0f;
                        vertex_data[v][i] = extract_int32(&level_data[current_byte_index + current_byte_offset]) / 256.0f / 256.0f;  // Note: Only untitled.dat seems to be this far off
                    }
                }

                #undef vertex_component_count

                current_byte_index += component_count * 4;

                // TODO: Verify this works correctly
                bool is_back_visible = false;
                bool is_front_visible = false;
                bool is_left_visible = false;
                bool is_right_visible = false;
                bool is_top_visible = false;
                bool is_bottom_visible = false;

                for(size_t v = 0; v < vertex_count / vertices_per_face; ++v) {
                    float x = vertex_data[v * vertices_per_face][3];
                    float y = vertex_data[v * vertices_per_face][4];
                    float z = vertex_data[v * vertices_per_face][5];
                    bool is_found = false;

                    if(fabs(x) > fabs(y) && fabs(x) > fabs(z)) {
                        is_found = true;

                        if(x < 0) {
                            is_left_visible = true;
                        } else {
                            is_right_visible = true;
                        }
                    }

                    if(fabs(y) > fabs(x) && fabs(y) > fabs(z)) {
                        is_found = true;

                        if(y < 0) {
                            is_bottom_visible = true;
                        } else {
                            is_top_visible = true;
                        }
                    }

                    if(fabs(z) > fabs(x) && fabs(z) > fabs(y)) {
                        is_found = true;

                        if(z < 0) {
                            is_front_visible = true;
                        } else {
                            is_back_visible = true;
                        }
                    }

                    if(!is_found) {
                        fprintf(stderr, "Could not determine which side a vertex normal was for %zu - %g %g %g\n", v, x, y, z);
                        return kERROR_INVALID_LEVEL_DATA;
                    }
                }

                #undef vertices_per_face

                printf(" %s %s", extract_bool_str(is_back_visible), extract_bool_str(is_front_visible));
                printf(" %s %s", extract_bool_str(is_left_visible), extract_bool_str(is_right_visible));
                printf(" %s %s", extract_bool_str(is_top_visible), extract_bool_str(is_bottom_visible));

                printf(" 0 0 0 0 0 0 0 0 0 %u 0 0 0 0 WALL", object_id);

                // Giving up on UVs because the data gets thrown away in compile
                printf(" 0 0 %u %u 0", top_left_x, top_left_y);
                printf(" 0 0 %u %u 0", top_right_x, top_right_y);
                printf(" 0 0 %u %u 0", bottom_left_x, bottom_left_y);
                printf(" 0 0 %u %u 0", bottom_right_x, bottom_right_y);
                printf(" 0 0 0 0 0");
                printf(" 0 0 0 0 0");
                printf(" 0 0 0 0 0");
                printf(" 0 0 0 0 0");

                float back_z = -10000.0f, front_z = 10000.0f;
                for(size_t v = 0; v < vertex_count; ++v) {
                    back_z = max(back_z, vertex_data[v][2]);
                    front_z = min(front_z, vertex_data[v][2]);
                }

                printf(" %g %g %u\n", front_z, back_z, texture_id);
                break;
            }
            case kLEVEL_DATA_ENTRY_VINE: {
                current_byte_index += 2;
                printf("O");

                current_byte_index += 8;  // Skipping over subroutine name

                uint16_t origin_x = extract_uint16(&level_data[current_byte_index + 0]);
                uint16_t top_y = extract_uint16(&level_data[current_byte_index + 2]);
                uint16_t bottom_y = extract_uint16(&level_data[current_byte_index + 4]);
                uint16_t front_z = extract_uint16(&level_data[current_byte_index + 6]);
                // uint16_t back_z = extract_uint16(&level_data[current_byte_index + 8]);  // equals front_z here when compiled
                uint16_t object_id = extract_uint16(&level_data[current_byte_index + 10]);
                uint16_t texture_id = extract_uint16(&level_data[current_byte_index + 12]);
                current_byte_index += 20;

                uint16_t component_count = extract_uint16(&level_data[current_byte_index]) / 4;
                current_byte_index += 2;

                current_byte_index += component_count * 4;

                // OK to hard code front and back vis for vines
                // Can manually edit the file to fix it if necessary
                printf(" True True True True True False");
                printf(" 0 0 0 0 0 0 0 0 0 %u 0 0 0 0 VINE", object_id);

                // Giving up on UVs because the data gets thrown away in compile
                // Also only writing out two vertices, because the other 6 don't get used by the compiler
                printf(" 0 0 %u %u 0", origin_x, top_y);
                printf(" 0 0 0 %u 0", bottom_y);
                printf(" 0 0 0 0 0");
                printf(" 0 0 0 0 0");
                printf(" 0 0 0 0 0");
                printf(" 0 0 0 0 0");
                printf(" 0 0 0 0 0");
                printf(" 0 0 0 0 0");

                printf(" %u %u %u\n", front_z, front_z + 1, texture_id);
                break;
            }
            case kLEVEL_DATA_ENTRY_DONUT: {
                current_byte_index += 2;
                printf("O");

                current_byte_index += 8;  // Skipping over subroutine name

                uint16_t origin_x = extract_uint16(&level_data[current_byte_index + 0]);
                uint16_t origin_y = extract_uint16(&level_data[current_byte_index + 2]);
                uint16_t front_z = extract_uint16(&level_data[current_byte_index + 4]);
                uint16_t object_id = extract_uint16(&level_data[current_byte_index + 6]);
                uint16_t texture_id = extract_uint16(&level_data[current_byte_index + 8]);
                current_byte_index += 20;

                uint16_t count = extract_uint16(&level_data[current_byte_index]) / 4;
                current_byte_index += 2;

                current_byte_index += count * 4;

                // OK to hard code front and back vis for donuts
                // Can manually edit the file to fix it if necessary
                printf(" True True True True True False");
                printf(" 0 0 0 0 0 0 0 0 0 %u 0 0 0 0 DONUT", object_id);

                printf(" 0 0 %u %u 0", origin_x, origin_y);
                printf(" 0 0 0 0 0");
                printf(" 0 0 0 0 0");
                printf(" 0 0 0 0 0");
                printf(" 0 0 0 0 0");
                printf(" 0 0 0 0 0");
                printf(" 0 0 0 0 0");
                printf(" 0 0 0 0 0");

                printf(" %u %u %u\n", front_z, front_z + 1, texture_id);
                break;
            }
            case kLEVEL_DATA_ENTRY_PLATFORM: {
                current_byte_index += 2;
                printf("O");

                current_byte_index += 8;  // Skipping over subroutine name

                uint16_t top_left_x = extract_uint16(&level_data[current_byte_index + 0]);
                uint16_t top_left_y = extract_uint16(&level_data[current_byte_index + 2]);
                uint16_t top_right_x = extract_uint16(&level_data[current_byte_index + 4]);
                uint16_t top_right_y = extract_uint16(&level_data[current_byte_index + 6]);
                uint16_t front_z = extract_uint16(&level_data[current_byte_index + 8]);
                uint16_t extra = extract_uint16(&level_data[current_byte_index + 10]);
                uint16_t object_id = extract_uint16(&level_data[current_byte_index + 12]);
                uint16_t texture_id = extract_uint16(&level_data[current_byte_index + 14]);
                current_byte_index += 20;

                uint16_t component_count = extract_uint16(&level_data[current_byte_index]) / 4;
                current_byte_index += 2;

                #define vertex_component_count 9
                const uint16_t vertex_count = component_count / vertex_component_count;
                const uint16_t expected_component_count = vertex_count * vertex_component_count;

                if(component_count != expected_component_count) {  // Validating it is divisible by vertex_component_count
                    fprintf(stderr, "Invalid count for Platform level data entry - expected: %u, actual: %u\n",
                        expected_component_count, component_count);
                    return kERROR_INVALID_LEVEL_DATA;
                }

                #define max_face_count 6
                #define vertices_per_face 6
                float vertex_data[max_face_count * vertices_per_face][vertex_component_count];

                #undef max_face_count

                for(size_t v = 0; v < vertex_count; ++v) {
                    for(size_t i = 0; i < vertex_component_count; ++i) {
                        size_t current_byte_offset = (v * vertex_component_count + i) * 4;
                        // vertex_data[v][i] = extract_int32(&level_data[current_byte_index + current_byte_offset]) / 256.0f;
                        vertex_data[v][i] = extract_int32(&level_data[current_byte_index + current_byte_offset]) / 256.0f / 256.0f;  // Note: Only untitled.dat seems to be this far off
                    }
                }

                #undef vertex_component_count

                current_byte_index += component_count * 4;

                // TODO: Verify this works correctly
                bool is_back_visible = false;
                bool is_front_visible = false;
                bool is_left_visible = false;
                bool is_right_visible = false;
                bool is_top_visible = false;
                bool is_bottom_visible = false;

                uint16_t bottom_left_x = top_left_x;
                uint16_t bottom_left_y = top_left_y;
                uint16_t bottom_right_x = top_right_x;
                uint16_t bottom_right_y = top_right_y;

                for(size_t v = 0; v < vertex_count / vertices_per_face; ++v) {
                    float x = vertex_data[v * vertices_per_face][3];
                    float y = vertex_data[v * vertices_per_face][4];
                    float z = vertex_data[v * vertices_per_face][5];
                    bool is_found = false;

                    if(fabs(x) > fabs(y) && fabs(x) > fabs(z)) {
                        is_found = true;

                        if(x < 0) {
                            is_left_visible = true;
                            bottom_left_x = (uint16_t)vertex_data[v * vertices_per_face + 2][0];
                            bottom_left_y = (uint16_t)vertex_data[v * vertices_per_face + 2][1];
                        } else {
                            is_right_visible = true;
                            bottom_right_x = (uint16_t)vertex_data[v * vertices_per_face + 2][0];
                            bottom_right_y = (uint16_t)vertex_data[v * vertices_per_face + 2][1];
                        }
                    }

                    if(fabs(y) > fabs(x) && fabs(y) > fabs(z)) {
                        is_found = true;

                        if(y < 0) {
                            is_bottom_visible = true;
                            // TODO: Which vertices?
                            // bottom_left_x = (uint16_t)vertex_data[v * vertices_per_face + 2][0];
                            // bottom_left_y = (uint16_t)vertex_data[v * vertices_per_face + 2][0];
                            // bottom_right_x = (uint16_t)vertex_data[v * vertices_per_face + 2][0];
                            // bottom_right_y = (uint16_t)vertex_data[v * vertices_per_face + 2][0];
                        } else {
                            is_top_visible = true;
                        }
                    }

                    if(fabs(z) > fabs(x) && fabs(z) > fabs(y)) {
                        is_found = true;

                        if(z < 0) {
                            is_front_visible = true;
                            // TODO: This seems to be breaking things?
                            // bottom_left_x = (uint16_t)vertex_data[v * vertices_per_face + 2][0];
                            // bottom_left_y = (uint16_t)vertex_data[v * vertices_per_face + 2][1];
                            // bottom_right_x = (uint16_t)vertex_data[v * vertices_per_face + 5][0];
                            // bottom_right_y = (uint16_t)vertex_data[v * vertices_per_face + 5][1];
                        } else {
                            is_back_visible = true;
                            // TODO: Which vertices?
                            // bottom_left_x = (uint16_t)vertex_data[v * vertices_per_face + 2][0];
                            // bottom_left_y = (uint16_t)vertex_data[v * vertices_per_face + 2][0];
                            // bottom_right_x = (uint16_t)vertex_data[v * vertices_per_face + 2][0];
                            // bottom_right_y = (uint16_t)vertex_data[v * vertices_per_face + 2][0];
                        }
                    }

                    if(!is_found) {
                        fprintf(stderr, "Could not determine which side a vertex normal was for %zu - %g %g %g\n", v, x, y, z);
                        return kERROR_INVALID_LEVEL_DATA;
                    }
                }

                #undef vertices_per_face

                printf(" %s %s", extract_bool_str(is_back_visible), extract_bool_str(is_front_visible));
                printf(" %s %s", extract_bool_str(is_left_visible), extract_bool_str(is_right_visible));
                printf(" %s %s", extract_bool_str(is_top_visible), extract_bool_str(is_bottom_visible));

                printf(" %u 0 0 0 0 0 0 0 0 %u 0 0 0 0 PLATFORM", extra, object_id);

                // Giving up on UVs because the data gets thrown away in compile
                printf(" 0 0 %u %u 0", top_left_x, top_left_y);
                printf(" 0 0 %u %u 0", top_right_x, top_right_y);
                printf(" 0 0 %u %u 0", bottom_left_x, bottom_left_y);
                printf(" 0 0 %u %u 0", bottom_right_x, bottom_right_y);
                printf(" 0 0 0 0 0");
                printf(" 0 0 0 0 0");
                printf(" 0 0 0 0 0");
                printf(" 0 0 0 0 0");

                float back_z = front_z;
                for(size_t v = 0; v < vertex_count; ++v) {
                    back_z = max(back_z, vertex_data[v][2]);
                }

                printf(" %u %g %u\n", front_z, back_z, texture_id);
                break;
            }
            default: {
                fprintf(stderr, "Invalid level data entry type id at byte %zu\n", current_byte_index);
                return kERROR_INVALID_LEVEL_DATA;
            }
        }
    }

    return kERROR_NO_ERROR;
}

int main(int argument_count, char* arguments[]) {
    if(argument_count < 2) {
        fprintf(stderr, "Must specify input file");
        return kERROR_INVALID_ARUGMENTS;
    } else if(argument_count > 2) {
        fprintf(stderr, "Too many arguments");
        return kERROR_INVALID_ARUGMENTS;
    }

    const char* input_filename = arguments[1];
    unsigned char* input_file_data = NULL;
    size_t input_file_size = 0;

    {
        FILE* input_file = fopen(input_filename, "rb");

        if(input_file) {
            fseek(input_file, 0, SEEK_END);
            input_file_size = ftell(input_file);
            fseek(input_file, 0, SEEK_SET);

            input_file_data = malloc(input_file_size);

            if(input_file_data) {
                fread(input_file_data, 1, input_file_size, input_file);
            } else {
                fprintf(stderr, "Failed to allocate %zu bytes\n", input_file_size);
                return kERROR_ALLOCATION_FAILED;
            }

            fclose(input_file);
        } else {
            fprintf(stderr, "Failed to open input file: %s\n", input_filename);
            return kERROR_INPUT_FILE_MISSING;
        }
    }

    int result = print_level(input_file_data, input_file_size);

    // Don't worry about calling free. We're exiting
    return result;
}
