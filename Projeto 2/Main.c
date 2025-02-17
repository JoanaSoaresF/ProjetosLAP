/*
 *  Cartography main
 * LAP AMD-2020
 *
 * COMPILAÇÃO: gcc -std=c11 -o Main Cartography.c Main.c -lm
 */
#define USE_PTS true
#include "Cartography.h"

static Cartography cartography;	// variavel gigante
static int nCartography = 0;

int main(void)
{
	nCartography = loadCartography("map1.txt", &cartography);
	showCartography(cartography, nCartography);
	interpreter(cartography, nCartography);
	return 0;
}
