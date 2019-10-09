#define _CRT_SECURE_NO_WARNINGS
#include <assert.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#ifdef _WIN32
    #include <direct.h>
    #define getcwd _getcwd
#else
    #include <unistd.h>
#endif

typedef struct {
    long X1, X2, X3, X4;
    long Y1, Y2, Y3, Y4;
    long Z1, Z2;
    long Num;
    char Func[10];
    long Extra;

    long MeshSize;
    long* Mesh;
    long MeshNumber;
    long Texture;
    int ObjectNumber;
} LevelObject;

long StringToLong2(unsigned char* sString) {
    float fTemp;

    fTemp = (sString[0] & 127) * 256.0f * 256.0f * 256.0f + sString[1] * 256.0f * 256.0f + sString[2] * 256.0f + sString[3];

    if(sString[0] & 128) {
        return (long)(fTemp) * -1;
    } else {
        return (long)(fTemp);
    }
}

long StringToInt(unsigned char* sString) {
    float fTemp;
    fTemp = sString[0] * 256.0f + sString[1];
    return (long)(fTemp);
}

static size_t FileToString(const char* filename, unsigned char** sNewBuffer) {
    long length = 0;
    FILE* input_file = fopen(filename, "rb");

    if(input_file) {
        fseek(input_file, 0, SEEK_END);
        length = ftell(input_file);
        fseek(input_file, 0, SEEK_SET);

        *sNewBuffer = (unsigned char*)malloc(length);

        if(*sNewBuffer) {
            fread(*sNewBuffer, 1, length, input_file);
        }

        fclose(input_file);
    }

    return length;
}

static void ComposeObject(LevelObject* lObj, long* oData, long* iPlace) {
    int iCopy = -1;

    while(++iCopy < lObj->MeshSize) {
        oData[*iPlace] = lObj->Mesh[iCopy];
        ++*iPlace;
    }
}

static void LoadLevel(const char* base_path, const char* filename) {
    char g_music_background_track_filename[200];
    char g_music_death_track_filename[200];
    char g_music_win_track_filename[200];
    int g_music_loop_start_music_time;

    char mesh_names[200][200];
    char mesh_filenames[200][200];
    char sound_names[200][200];
    char sound_filenames[200][200];
    char texture_names[200][200];
    char texture_filenames[200][200];

    size_t g_loaded_mesh_count = 0;
    size_t g_loaded_sound_count = 0;
    size_t g_loaded_texture_count = 0;

    LevelObject platform_objects[300] = { 0 };
    LevelObject ladder_objects[300] = { 0 };
    LevelObject donut_objects[300] = { 0 };
    LevelObject vine_objects[300] = { 0 };
    LevelObject wall_objects[300] = { 0 };
    LevelObject backdrop_objects[300] = { 0 };

    size_t g_platform_object_count = 0;
    size_t g_ladder_object_count = 0;
    size_t g_donut_object_count = 0;
    size_t g_vine_object_count = 0;
    size_t g_wall_object_count = 0;
    size_t g_backdrop_object_count = 0;

    char full_path[300];
    snprintf(full_path, sizeof(full_path), "%s/%s", base_path, filename);

    unsigned char* cData = NULL;
    size_t iLen = FileToString(full_path, &cData);
    size_t iPlace = 0;

    while(iPlace < iLen) {
        char sTemp[300] = { 0 };

        if(cData[iPlace] == 'R' && cData[iPlace + 1] == 0) {
            iPlace += 2;
            int iLoop = -1;

            while(++iLoop < 30) {
                sTemp[iLoop] = cData[iPlace + iLoop];
            }

            iPlace += 30;

            long iTemp = StringToInt(&cData[iPlace + 0]);
            long iArg1 = StringToInt(&cData[iPlace + 2]);
            long iArg2 = StringToInt(&cData[iPlace + 4]);

            if(iTemp == 1) {
                char sBuild[200];
                snprintf(sBuild, sizeof(sBuild), "sound/%s.mid", sTemp);

                if(iArg1 == 1) {
                    snprintf(g_music_background_track_filename, sizeof(g_music_background_track_filename), "%s", sBuild);
                    g_music_loop_start_music_time = (int)iArg2 * 10;
                }

                if(iArg1 == 2) {
                    snprintf(g_music_death_track_filename, sizeof(g_music_death_track_filename), "%s", sBuild);
                }

                if(iArg1 == 3) {
                    snprintf(g_music_win_track_filename, sizeof(g_music_win_track_filename), "%s", sBuild);
                }
            }

            if(iTemp == 2) {
                snprintf(mesh_names[g_loaded_mesh_count], sizeof(mesh_names[g_loaded_mesh_count]), "%s", sTemp);
                snprintf(mesh_filenames[g_loaded_mesh_count], sizeof(mesh_filenames[g_loaded_mesh_count]), "%s.msh", sTemp);
                ++g_loaded_mesh_count;
            }

            if(iTemp == 7) {
                snprintf(sound_names[g_loaded_sound_count], sizeof(sound_names[g_loaded_sound_count]), "%s", sTemp);
                snprintf(sound_filenames[g_loaded_sound_count], sizeof(sound_filenames[g_loaded_sound_count]), "sound/%s.wav", sTemp);
                ++g_loaded_sound_count;
            }

            if(iTemp == 3 || iTemp == 4 || iTemp == 6) {
                snprintf(texture_names[g_loaded_texture_count], sizeof(texture_names[g_loaded_texture_count]), "%s", sTemp);

                char sBuild[200];
                snprintf(sBuild, sizeof(sBuild), "data/%s", sTemp);

                if(iTemp == 3) {
                    snprintf(texture_filenames[g_loaded_texture_count], sizeof(texture_filenames[g_loaded_texture_count]), "%s%s", sBuild, ".bmp");
                }

                if(iTemp == 4) {
                    snprintf(texture_filenames[g_loaded_texture_count], sizeof(texture_filenames[g_loaded_texture_count]), "%s%s", sBuild, ".jpg");
                }

                if(iTemp == 6) {
                    snprintf(texture_filenames[g_loaded_texture_count], sizeof(texture_filenames[g_loaded_texture_count]), "%s%s", sBuild, ".png");
                }

                ++g_loaded_texture_count;
            }

            if(iTemp == 5) {
                // Don't care. Loading scripts from inside level scripts now
            }

            iPlace += 8;
        } else if(cData[iPlace] == 'A' && cData[iPlace + 1] == 0) {
            LevelObject backdrop_object = { 0 };

            iPlace += 10;

            backdrop_object.Texture = StringToInt(&cData[iPlace + 0]);
            backdrop_object.X1 = StringToInt(&cData[iPlace + 2]);
            backdrop_object.Y1 = StringToInt(&cData[iPlace + 4]);
            backdrop_object.Num = StringToInt(&cData[iPlace + 6]);
            iPlace += 20;

            long iData = StringToInt(&cData[iPlace]) / 4;
            iPlace += 2;

            backdrop_object.Mesh = (long*)(malloc(iData * sizeof(long)));
            backdrop_object.MeshSize = iData;
            backdrop_object.ObjectNumber = (int)g_backdrop_object_count;

            long iNum = -1;

            while(++iNum < iData) {
                backdrop_object.Mesh[iNum] = StringToLong2(&cData[iPlace + (iNum << 2)]);
            }

            iPlace += iNum << 2;

            long* oData = (long*)(malloc(backdrop_object.MeshSize * sizeof(long)));
            long iMPlace = 0;
            ComposeObject(&backdrop_object, oData, &iMPlace);
            // CreateObject(oData, iMPlace / 9, &iNum);

            backdrop_object.MeshNumber = iNum;
            free(oData);

            backdrop_objects[g_backdrop_object_count] = backdrop_object;
            ++g_backdrop_object_count;
        } else if(cData[iPlace] == 'L' && cData[iPlace + 1] == 0) {
            LevelObject ladder_object = { 0 };

            int iLoop = -1;

            while(++iLoop < 8) {
                ladder_object.Func[iLoop] = cData[iPlace + 2 + iLoop];
            }

            iPlace += 10;

            ladder_object.X1 = StringToInt(&cData[iPlace + 0]);
            ladder_object.Y1 = StringToInt(&cData[iPlace + 2]);
            ladder_object.Y2 = StringToInt(&cData[iPlace + 4]);
            ladder_object.Z1 = StringToInt(&cData[iPlace + 6]);
            ladder_object.Z2 = StringToInt(&cData[iPlace + 8]);
            ladder_object.Num = StringToInt(&cData[iPlace + 10]);
            ladder_object.Texture = StringToInt(&cData[iPlace + 12]);
            iPlace += 20;

            long iData = StringToInt(&cData[iPlace]) / 4;
            iPlace += 2;

            ladder_object.Mesh = (long*)(malloc(iData * sizeof(long)));
            ladder_object.MeshSize = iData;
            ladder_object.ObjectNumber = (int)g_ladder_object_count;

            long iNum = -1;

            while(++iNum < iData) {
                ladder_object.Mesh[iNum] = StringToLong2(&cData[iPlace + (iNum << 2)]);
            }

            iPlace += iNum << 2;

            long* oData = (long*)(malloc(ladder_object.MeshSize * sizeof(long)));
            long iMPlace = 0;
            ComposeObject(&ladder_object, oData, &iMPlace);
            // CreateObject(oData, iMPlace / 9, &iNum);
            ladder_object.MeshNumber = iNum;
            free(oData);

            ladder_objects[g_ladder_object_count] = ladder_object;
            ++g_ladder_object_count;
        } else if(cData[iPlace] == 'W' && cData[iPlace + 1] == 0) {
            LevelObject wall_object = { 0 };

            int iLoop = -1;

            while(++iLoop < 8) {
                wall_object.Func[iLoop] = cData[iPlace + 2 + iLoop];
            }

            iPlace += 10;

            wall_object.X1 = StringToInt(&cData[iPlace + 0]);
            wall_object.Y1 = StringToInt(&cData[iPlace + 2]);
            wall_object.X2 = StringToInt(&cData[iPlace + 4]);
            wall_object.Y2 = StringToInt(&cData[iPlace + 6]);
            wall_object.X3 = StringToInt(&cData[iPlace + 8]);
            wall_object.Y3 = StringToInt(&cData[iPlace + 10]);
            wall_object.X4 = StringToInt(&cData[iPlace + 12]);
            wall_object.Y4 = StringToInt(&cData[iPlace + 14]);

            wall_object.Num = StringToInt(&cData[iPlace + 16]);
            wall_object.Texture = StringToInt(&cData[iPlace + 18]);

            iPlace += 20;

            long iData = StringToInt(&cData[iPlace]) / 4;
            iPlace += 2;

            wall_object.Mesh = (long*)(malloc(iData * sizeof(long)));
            wall_object.MeshSize = iData;
            wall_object.ObjectNumber = (int)g_wall_object_count;

            long iNum = -1;

            while(++iNum < iData) {
                wall_object.Mesh[iNum] = StringToLong2(&cData[iPlace + (iNum << 2)]);
            }

            iPlace += iNum << 2;

            long* oData = (long*)(malloc(wall_object.MeshSize * sizeof(long)));
            long iMPlace = 0;
            ComposeObject(&wall_object, oData, &iMPlace);
            // CreateObject(oData, iMPlace / 9, &iNum);
            wall_object.MeshNumber = iNum;
            free(oData);

            wall_objects[g_wall_object_count] = wall_object;
            ++g_wall_object_count;
        } else if(cData[iPlace] == 'V' && cData[iPlace + 1] == 0) {
            LevelObject vine_object = { 0 };

            int iLoop = -1;

            while(++iLoop < 8) {
                vine_object.Func[iLoop] = cData[iPlace + 2 + iLoop];
            }

            iPlace += 10;

            vine_object.X1 = StringToInt(&cData[iPlace + 0]);
            vine_object.Y1 = StringToInt(&cData[iPlace + 2]);
            vine_object.Y2 = StringToInt(&cData[iPlace + 4]);
            vine_object.Z1 = StringToInt(&cData[iPlace + 6]);
            vine_object.Z2 = StringToInt(&cData[iPlace + 8]);
            vine_object.Num = StringToInt(&cData[iPlace + 10]);
            vine_object.Texture = StringToInt(&cData[iPlace + 12]);
            iPlace += 20;

            long iData = StringToInt(&cData[iPlace]) / 4;
            iPlace += 2;

            vine_object.Mesh = (long*)(malloc(iData * sizeof(long)));
            vine_object.MeshSize = iData;
            vine_object.ObjectNumber = (int)g_vine_object_count;

            long iNum = -1;

            while(++iNum < iData) {
                vine_object.Mesh[iNum] = StringToLong2(&cData[iPlace + (iNum << 2)]);
            }

            iPlace += iNum << 2;

            long* oData = (long*)(malloc(vine_object.MeshSize * sizeof(long)));
            long iMPlace = 0;
            ComposeObject(&vine_object, oData, &iMPlace);
            // CreateObject(oData, iMPlace / 9, &iNum);
            vine_object.MeshNumber = iNum;
            free(oData);

            vine_objects[g_vine_object_count] = vine_object;
            ++g_vine_object_count;
        } else if(cData[iPlace] == 'D' && cData[iPlace + 1] == 0) {
            LevelObject donut_object = { 0 };

            int iLoop = -1;

            while(++iLoop < 8) {
                donut_object.Func[iLoop] = cData[iPlace + 2 + iLoop];
            }

            iPlace += 10;

            donut_object.X1 = StringToInt(&cData[iPlace + 0]);
            donut_object.Y1 = StringToInt(&cData[iPlace + 2]);
            donut_object.Z1 = StringToInt(&cData[iPlace + 4]);
            donut_object.Num = StringToInt(&cData[iPlace + 6]);
            donut_object.Texture = StringToInt(&cData[iPlace + 8]);
            iPlace += 20;

            long iData = StringToInt(&cData[iPlace]) / 4;
            iPlace += 2;

            donut_object.Mesh = (long*)(malloc(iData * sizeof(long)));
            donut_object.MeshSize = iData;
            donut_object.ObjectNumber = (int)g_donut_object_count;

            long iNum = -1;

            while(++iNum < iData) {
                donut_object.Mesh[iNum] = StringToLong2(&cData[iPlace + (iNum << 2)]);
            }

            iPlace += iNum << 2;

            long* oData = (long*)(malloc(donut_object.MeshSize * sizeof(long)));
            long iMPlace = 0;
            ComposeObject(&donut_object, oData, &iMPlace);
            // CreateObject(oData, iMPlace / 9, &iNum);
            donut_object.MeshNumber = iNum;
            free(oData);

            donut_objects[g_donut_object_count] = donut_object;
            ++g_donut_object_count;
        } else if(cData[iPlace] == 'P' && cData[iPlace + 1] == 0) {
            LevelObject platform_object = { 0 };

            int iLoop = -1;

            while(++iLoop < 8) {
                platform_object.Func[iLoop] = cData[iPlace + 2 + iLoop];
            }

            iPlace += 10;

            platform_object.X1 = StringToInt(&cData[iPlace + 0]);
            platform_object.Y1 = StringToInt(&cData[iPlace + 2]);
            platform_object.X2 = StringToInt(&cData[iPlace + 4]);
            platform_object.Y2 = StringToInt(&cData[iPlace + 6]);
            platform_object.Z1 = StringToInt(&cData[iPlace + 8]);
            platform_object.Extra = StringToInt(&cData[iPlace + 10]);
            platform_object.Num = StringToInt(&cData[iPlace + 12]);
            platform_object.Texture = StringToInt(&cData[iPlace + 14]);
            iPlace += 20;

            long iData = StringToInt(&cData[iPlace]) / 4;
            iPlace += 2;

            platform_object.Mesh = (long*)(malloc(iData * sizeof(long)));
            platform_object.MeshSize = iData;
            platform_object.ObjectNumber = (int)g_platform_object_count;

            long iNum = -1;

            while(++iNum < iData) {
                platform_object.Mesh[iNum] = StringToLong2(&cData[iPlace + (iNum << 2)]);
            }

            iPlace += iNum << 2;

            long* oData = (long*)(malloc(platform_object.MeshSize * sizeof(long)));
            long iMPlace = 0;
            ComposeObject(&platform_object, oData, &iMPlace);
            // CreateObject(oData, iMPlace / 9, &iNum);
            platform_object.MeshNumber = iNum;
            free(oData);

            platform_objects[g_platform_object_count] = platform_object;
            ++g_platform_object_count;
        } else {
            // TODO: Additional error handling?
            fprintf(stderr, "GOT TO ERROR HANDLING BLOCK: %s\n", filename);
            return;
        }
    }

    free(cData);

    printf("return {");

    printf(
        "\n    music_background_track_filename = \"%s\","
        "\n    music_death_track_filename = \"%s\","
        "\n    music_win_track_filename = \"%s\","
        "\n    music_loop_start_music_time = %d,"
        , g_music_background_track_filename
        , g_music_death_track_filename
        , g_music_win_track_filename
        , g_music_loop_start_music_time
    );

    printf(
        "\n    meshes = {"
    );

    for(size_t i = 0; i < g_loaded_mesh_count; ++i) {
        printf("\n        { name = \"%s\", filename = \"%s\" },", mesh_names[i], mesh_filenames[i]);
    }

    printf(
        "\n    },"
    );

    printf(
        "\n    textures = {"
    );

    for(size_t i = 0; i < g_loaded_texture_count; ++i) {
        printf("\n        { name = \"%s\", filename = \"%s\" },", texture_names[i], texture_filenames[i]);
    }

    printf(
        "\n    },"
    );

    printf(
        "\n    sounds = {"
    );

    for(size_t i = 0; i < g_loaded_sound_count; ++i) {
        printf("\n        { name = \"%s\", filename = \"%s\" },", sound_names[i], sound_filenames[i]);
    }

    printf(
        "\n    },"
    );


    printf(
        "\n    donuts = {"
    );

    for(size_t i = 0; i < g_donut_object_count; ++i) {
        LevelObject donut = donut_objects[i];
        printf(
            "\n        {"
            "\n            number = %d,"
            "\n            texture_index = %d,"
            "\n            pos = { %d, %d, %d }"
            "\n            mesh = {"
            , donut.Num
            , donut.Texture
            , donut.X1
            , donut.Y1
            , donut.Z1
        );

        for(size_t mesh_index = 0; mesh_index < donut.MeshSize / 9; ++mesh_index) {
            printf(
                "\n                { pos = { %g, %g, %g }, normal = { %g, %g, %g }, uv = { %g, %g } },"
                , donut.Mesh[mesh_index * 9 + 0] / 256.0f
                , donut.Mesh[mesh_index * 9 + 1] / 256.0f
                , donut.Mesh[mesh_index * 9 + 2] / 256.0f
                , donut.Mesh[mesh_index * 9 + 3] / 256.0f
                , donut.Mesh[mesh_index * 9 + 4] / 256.0f
                , donut.Mesh[mesh_index * 9 + 5] / 256.0f
                , donut.Mesh[mesh_index * 9 + 7] / 256.0f
                , donut.Mesh[mesh_index * 9 + 8] / 256.0f
            );
        }

        printf(
            "\n            },"
            "\n        },"
        );
    }

    printf(
        "\n    },"
    );

    printf(
        "\n    platforms = {"
    );

    for(size_t i = 0; i < g_platform_object_count; ++i) {
        LevelObject platform = platform_objects[i];
        printf(
            "\n        {"
            "\n            number = %d,"
            "\n            extra = %d,"
            "\n            texture_index = %d,"
            "\n            lower_left = { %d, %d },"
            "\n            upper_right = { %d, %d },"
            "\n            z = %d,"
            "\n            mesh = {"
            , platform.Num
            , platform.Extra
            , platform.Texture
            , platform.X1
            , platform.Y1
            , platform.X2
            , platform.Y2
            , platform.Z1
        );

        for(size_t mesh_index = 0; mesh_index < platform.MeshSize / 9; ++mesh_index) {
            printf(
                "\n                { pos = { %g, %g, %g }, normal = { %g, %g, %g }, uv = { %g, %g } },"
                , platform.Mesh[mesh_index * 9 + 0] / 256.0f
                , platform.Mesh[mesh_index * 9 + 1] / 256.0f
                , platform.Mesh[mesh_index * 9 + 2] / 256.0f
                , platform.Mesh[mesh_index * 9 + 3] / 256.0f
                , platform.Mesh[mesh_index * 9 + 4] / 256.0f
                , platform.Mesh[mesh_index * 9 + 5] / 256.0f
                , platform.Mesh[mesh_index * 9 + 7] / 256.0f
                , platform.Mesh[mesh_index * 9 + 8] / 256.0f
            );
        }

        printf(
            "\n            },"
            "\n        },"
        );
    }

    printf(
        "\n    },"
    );

    printf(
        "\n    ladders = {"
    );

    for(size_t i = 0; i < g_ladder_object_count; ++i) {
        LevelObject ladder = ladder_objects[i];
        printf(
            "\n        {"
            "\n            number = %d,"
            "\n            texture_index = %d,"
            "\n            x_pos = %d,"
            "\n            y_top = %d,"
            "\n            y_bottom = %d,"
            "\n            z_front = %d,"
            "\n            z_back = %d,"
            "\n            mesh = {"
            , ladder.Num
            , ladder.Texture
            , ladder.X1
            , ladder.Y1
            , ladder.Y2
            , ladder.Z1
            , ladder.Z2
        );

        for(size_t mesh_index = 0; mesh_index < ladder.MeshSize / 9; ++mesh_index) {
            printf(
                "\n                { pos = { %g, %g, %g }, normal = { %g, %g, %g }, uv = { %g, %g } },"
                , ladder.Mesh[mesh_index * 9 + 0] / 256.0f
                , ladder.Mesh[mesh_index * 9 + 1] / 256.0f
                , ladder.Mesh[mesh_index * 9 + 2] / 256.0f
                , ladder.Mesh[mesh_index * 9 + 3] / 256.0f
                , ladder.Mesh[mesh_index * 9 + 4] / 256.0f
                , ladder.Mesh[mesh_index * 9 + 5] / 256.0f
                , ladder.Mesh[mesh_index * 9 + 7] / 256.0f
                , ladder.Mesh[mesh_index * 9 + 8] / 256.0f
            );
        }

        printf(
            "\n            },"
            "\n        },"
        );
    }

    printf(
        "\n    },"
    );

    printf(
        "\n    vines = {"
    );

    for(size_t i = 0; i < g_vine_object_count; ++i) {
        LevelObject vine = vine_objects[i];
        printf(
            "\n        {"
            "\n            number = %d,"
            "\n            texture_index = %d,"
            "\n            x_pos = %d,"
            "\n            y_top = %d,"
            "\n            y_bottom = %d,"
            "\n            z_front = %d,"
            "\n            z_back = %d,"
            "\n            mesh = {"
            , vine.Num
            , vine.Texture
            , vine.X1
            , vine.Y1
            , vine.Y2
            , vine.Z1
            , vine.Z2
        );

        for(size_t mesh_index = 0; mesh_index < vine.MeshSize / 9; ++mesh_index) {
            printf(
                "\n                { pos = { %g, %g, %g }, normal = { %g, %g, %g }, uv = { %g, %g } },"
                , vine.Mesh[mesh_index * 9 + 0] / 256.0f
                , vine.Mesh[mesh_index * 9 + 1] / 256.0f
                , vine.Mesh[mesh_index * 9 + 2] / 256.0f
                , vine.Mesh[mesh_index * 9 + 3] / 256.0f
                , vine.Mesh[mesh_index * 9 + 4] / 256.0f
                , vine.Mesh[mesh_index * 9 + 5] / 256.0f
                , vine.Mesh[mesh_index * 9 + 7] / 256.0f
                , vine.Mesh[mesh_index * 9 + 8] / 256.0f
            );
        }

        printf(
            "\n            },"
            "\n        },"
        );
    }

    printf(
        "\n    },"
    );

    printf(
        "\n    walls = {"
    );

    for(size_t i = 0; i < g_wall_object_count; ++i) {
        LevelObject wall = wall_objects[i];
        printf(
            "\n        {"
            "\n            number = %d,"
            "\n            texture_index = %d,"
            "\n            pos = { { %d, %d }, { %d, %d }, { %d, %d }, { %d, %d } },"
            "\n            mesh = {"
            , wall.Num
            , wall.Texture
            , wall.X1
            , wall.Y1
            , wall.X2
            , wall.Y2
            , wall.X3
            , wall.Y3
            , wall.X4
            , wall.Y4
        );

        for(size_t mesh_index = 0; mesh_index < wall.MeshSize / 9; ++mesh_index) {
            printf(
                "\n                { pos = { %g, %g, %g }, normal = { %g, %g, %g }, uv = { %g, %g } },"
                , wall.Mesh[mesh_index * 9 + 0] / 256.0f
                , wall.Mesh[mesh_index * 9 + 1] / 256.0f
                , wall.Mesh[mesh_index * 9 + 2] / 256.0f
                , wall.Mesh[mesh_index * 9 + 3] / 256.0f
                , wall.Mesh[mesh_index * 9 + 4] / 256.0f
                , wall.Mesh[mesh_index * 9 + 5] / 256.0f
                , wall.Mesh[mesh_index * 9 + 7] / 256.0f
                , wall.Mesh[mesh_index * 9 + 8] / 256.0f
            );
        }

        printf(
            "\n            },"
            "\n        },"
        );
    }

    printf(
        "\n    },"
    );

    printf(
        "\n    backdrops = {"
    );

    for(size_t i = 0; i < g_backdrop_object_count; ++i) {
        LevelObject backdrop = backdrop_objects[i];
        printf(
            "\n        {"
            "\n            number = %d,"
            "\n            texture_index = %d,"
            "\n            pos = { %d, %d },"
            "\n            mesh = {"
            , backdrop.Num
            , backdrop.Texture
            , backdrop.X1
            , backdrop.Y1
        );

        for(size_t mesh_index = 0; mesh_index < backdrop.MeshSize / 9; ++mesh_index) {
            printf(
                "\n                { pos = { %g, %g, %g }, normal = { %g, %g, %g }, uv = { %g, %g } },"
                , backdrop.Mesh[mesh_index * 9 + 0] / 256.0f
                , backdrop.Mesh[mesh_index * 9 + 1] / 256.0f
                , backdrop.Mesh[mesh_index * 9 + 2] / 256.0f
                , backdrop.Mesh[mesh_index * 9 + 3] / 256.0f
                , backdrop.Mesh[mesh_index * 9 + 4] / 256.0f
                , backdrop.Mesh[mesh_index * 9 + 5] / 256.0f
                , backdrop.Mesh[mesh_index * 9 + 7] / 256.0f
                , backdrop.Mesh[mesh_index * 9 + 8] / 256.0f
            );
        }

        printf(
            "\n            },"
            "\n        },"
        );
    }

    printf(
        "\n    },"
    );

    printf(
        "\n};"
        "\n"
    );
}

bool GetWorkingDirectoryPath(char* output_path) {
    if(getcwd(output_path, 200) == NULL) {
        return false;
    }

    return true;
}

int main(int argument_count, char* arguments[]) {
    if(argument_count < 2) {
        fprintf(stderr, "Must specify input file");
        return -1;
    } else if(argument_count > 2) {
        fprintf(stderr, "Too many arguments");
        return -1;
    }

    char game_base_path[300];
    const char* input_filename = arguments[1];

    if(!GetWorkingDirectoryPath(game_base_path)) {
        return -1;
    }

    LoadLevel(game_base_path, input_filename);

    return 0;
}
