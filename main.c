#include <stdio.h>
#include <stdbool.h>
#include "SDL.h"


#define SWAP(x, y) do {typeof(x) _swap = x; x = y; y = _swap;} while (0)
#define ISBETWEEN(x, min, max) ((min) <= (x) && (x) < (max))


const int SCREEN_WIDTH = 600;
const int SCREEN_HEIGHT = 600;


typedef struct {
    int x;
    int y;
} Point;


/* Sort the points ascending */
void sort(Point* points, int n) {
    for (int i = 1; i < n; i++) {
        Point val = points[i];
        int j = i - 1;
        while (j >= 0 && points[j].y > val.y) {
            points[j + 1] = points[j];
            j--;
        }
        points[j+1] = val;
    }
}


void draw_horz_line(SDL_Surface* surf, int x1, int x2, int y, Uint32 col) {
    if (x1 > x2) {
        SWAP(x1, x2);
    }
    Uint8* row = surf->pixels + y*surf->pitch;
    for (int x = x1; x <= x2; x++) {
        *((Uint32*) (row + x * sizeof(Uint32))) = col;
        // set_pixel(surf, x, y, col);
    }
}


void draw_triangle(SDL_Surface *surf, Point p1, Point p2, Point p3) {
    Point points[3] = {p1, p2, p3};
    sort(points, 3);
    p1 = points[0];
    p2 = points[1];
    p3 = points[2];

    Uint32 white = SDL_MapRGB(surf->format, 0xFF, 0xFF, 0xFF);

    double slope1, slope2;
    slope1 = (double) (p1.x - p2.x) / (p1.y - p2.y);
    slope2 = (double) (p1.x - p3.x) / (p1.y - p3.y);

    double x1 = p1.x;
    double x2 = p1.x;
    for (int y = p1.y; y < p3.y; y++) {
        if (y == p2.y) {
            slope1 = (double) (p2.x - p3.x) / (p2.y - p3.y);
            x1 = p2.x;
        }
        draw_horz_line(surf, (int) x1, (int) x2, y, white);

        x1 += slope1;
        x2 += slope2;
    }
}


int main(int argc, char* args[]) {
    SDL_Window* window = NULL;
    SDL_Surface* screen = NULL;

    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        printf("SDL initialization error: %s\n", SDL_GetError());
        return 1;
    }

    window = SDL_CreateWindow("SDL Tutorial", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, SCREEN_WIDTH, SCREEN_HEIGHT, SDL_WINDOW_SHOWN);
    if (window == NULL) {
        printf("Window could not be created! %s\n", SDL_GetError());
        return 1;
    }

    screen = SDL_GetWindowSurface(window);
    Uint32 BLACK = SDL_MapRGB(screen->format, 0x00, 0x00, 0x00);


    SDL_Event e;

    bool quit = false;
    while (!quit) {
        SDL_FillRect(screen, NULL, BLACK);

        while (SDL_PollEvent(&e)) {
            switch (e.type) {
                case SDL_QUIT:
                case SDL_KEYDOWN:
                case SDL_MOUSEBUTTONDOWN:
                    quit = true;
                    break;
                default:
                    break;
            }
        }

        draw_triangle(screen, (Point) {140, 200}, (Point) {100, 100}, (Point) {50, 150});
        SDL_UpdateWindowSurface(window);
    }

    SDL_DestroyWindow(window);

    SDL_Quit();
    return 0;
}