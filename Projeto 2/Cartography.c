/*
largura maxima = 100 colunas
tab = 4 espaços
0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789

	Linguagens e Ambientes de Programação (B) - Projeto de 2019/20

	Cartography.c

	Este ficheiro constitui apenas um ponto de partida para o
	seu trabalho. Todo este ficheiro pode e deve ser alterado
	à vontade, a começar por este comentário. É preciso inventar
	muitas funções novas.

COMPILAÇÃO

  gcc -std=c11 -o Main Cartography.c Main.c -lm

IDENTIFICAÇÃO DOS AUTORES

  Aluno 1: 55780 Goncalo Lourenco
  Aluno 2: 55754 Joana Faria

COMENTÁRIO

 Coloque aqui a identificação do grupo, mais os seus comentários, como
 se pede no enunciado.

*/
#define USE_PTS true
#include "Cartography.h"

/* STRING -------------------------------------- */

static void showStringVector(StringVector sv, int n)
{
	int i;
	for (i = 0; i < n; i++)
	{
		printf("%s\n", sv[i]);
	}
}

/* UTIL */

static void error(String message)
{
	fprintf(stderr, "%s.\n", message);
	exit(1); // Termina imediatamente a execucao do programa
}

static void readLine(String line, FILE *f) // le uma linha que existe obrigatoriamente
{
	if (fgets(line, MAX_STRING, f) == NULL)
		error("Ficheiro invalido");
	line[strlen(line) - 1] = '\0'; // elimina o '\n'
}

static int readInt(FILE *f)
{
	int i;
	String line;
	readLine(line, f);
	sscanf(line, "%d", &i);
	return i;
}

/* IDENTIFICATION -------------------------------------- */

static Identification readIdentification(FILE *f)
{
	Identification id;
	String line;
	readLine(line, f);
	sscanf(line, "%s %s %s", id.freguesia, id.concelho, id.distrito);
	return id;
}

static void showIdentification(int pos, Identification id, int z)
{
	if (pos >= 0) // pas zero interpretado como nao mostrar
		printf("%4d ", pos);
	else
		printf("%4s ", "");
	if (z == 3)
		printf("%-25s %-13s %-22s", id.freguesia, id.concelho, id.distrito);
	else if (z == 2)
		printf("%-25s %-13s %-22s", "", id.concelho, id.distrito);
	else
		printf("%-25s %-13s %-22s", "", "", id.distrito);
}

static void showValue(int value)
{
	if (value < 0) // value negativo interpretado como char
		printf(" [%c]\n", -value);
	else
		printf(" [%3d]\n", value);
}

static bool sameIdentification(Identification id1, Identification id2, int z)
{
	if (z == 3)
		return strcmp(id1.freguesia, id2.freguesia) == 0 && strcmp(id1.concelho, id2.concelho) == 0 && strcmp(id1.distrito, id2.distrito) == 0;
	else if (z == 2)
		return strcmp(id1.concelho, id2.concelho) == 0 && strcmp(id1.distrito, id2.distrito) == 0;
	else
		return strcmp(id1.distrito, id2.distrito) == 0;
}

/* COORDINATES -------------------------------------- */

Coordinates coord(double lat, double lon)
{
	Coordinates c = {lat, lon};
	return c;
}

static Coordinates readCoordinates(FILE *f)
{
	double lat, lon;
	String line;
	readLine(line, f);
	sscanf(line, "%lf %lf", &lat, &lon);
	return coord(lat, lon);
}

bool sameCoordinates(Coordinates c1, Coordinates c2)
{
	return c1.lat == c2.lat && c1.lon == c2.lon;
}

static double toRadians(double deg)
{
	return deg * PI / 180.0;
}

// https://en.wikipedia.org/wiki/Haversine_formula
double haversine(Coordinates c1, Coordinates c2)
{
	double dLat = toRadians(c2.lat - c1.lat);
	double dLon = toRadians(c2.lon - c1.lon);

	double sa = sin(dLat / 2.0);
	double so = sin(dLon / 2.0);

	double a = sa * sa + so * so * cos(toRadians(c1.lat)) * cos(toRadians(c2.lat));
	return EARTH_RADIUS * (2 * asin(sqrt(a)));
}

/* RECTANGLE -------------------------------------- */

Rectangle rect(Coordinates tl, Coordinates br)
{
	Rectangle rect = {tl, br};
	return rect;
}

static void showRectangle(Rectangle r)
{
	printf("{%lf, %lf, %lf, %lf}",
		   r.topLeft.lat, r.topLeft.lon,
		   r.bottomRight.lat, r.bottomRight.lon);
}

static Rectangle calculateBoundingBox(Coordinates vs[], int n)
{
	// TODO

	double bottomLat = vs[0].lat, topLat = vs[0].lat;
	double bottomLon = vs[0].lon, topLon = vs[0].lon;
	for (int i = 1; i < n; i++)
	{
		double lat = vs[i].lat;
		double lon = vs[i].lon;

		if (lat > topLat)
			topLat = lat;

		if (lat < bottomLat)
			bottomLat = lat;

		if (lon < topLon)
			topLon = lon;

		if (lon > bottomLon)
			bottomLon = lon;
	}

	return rect(coord(topLat, topLon), coord(bottomLat, bottomLon));
}

bool insideRectangle(Coordinates c, Rectangle r)
{
	return c.lat >= r.bottomRight.lat && c.lat <= r.topLeft.lat && c.lon >= r.topLeft.lon && c.lon <= r.bottomRight.lon;
}

/* RING -------------------------------------- */

static Ring readRing(FILE *f)
{
	Ring r;
	int i, n = readInt(f);
	//if( n > MAX_VERTEXES )
	//	error("Anel demasiado extenso");
	r.nVertexes = n;
	r.vertexes = malloc(n * sizeof(Coordinates));

	for (i = 0; i < n; i++)
	{
		r.vertexes[i] = readCoordinates(f); // !!malloc
	}
	r.boundingBox =
		calculateBoundingBox(r.vertexes, r.nVertexes);
	return r;
}

// http://alienryderflex.com/polygon/
bool insideRing(Coordinates c, Ring r)
{
	double x = c.lon, y = c.lat;
	int i, j;
	bool oddNodes = false;
	for (i = 0, j = r.nVertexes - 1; i < r.nVertexes; j = i++)
	{
		double xi = r.vertexes[i].lon, yi = r.vertexes[i].lat;
		double xj = r.vertexes[j].lon, yj = r.vertexes[j].lat;
		if (((yi < y && y <= yj) || (yj < y && y <= yi)) && (xi <= x || xj <= x))
		{
			oddNodes ^= (xi + (y - yi) / (yj - yi) * (xj - xi)) < x;
		}
	}
	return oddNodes;
}

bool adjacentRings(Ring a, Ring b)
{
	bool touch = false;
	Rectangle auxR = b.boundingBox;

	for (int i = 0; i < a.nVertexes && !touch; i++)
	{
		if (insideRectangle(a.vertexes[i], auxR))
		{
			for (int j = 0; j < b.nVertexes && !touch; j++)
			{
				if (sameCoordinates(a.vertexes[i], b.vertexes[j]))
					touch = true;
			}
		}
	}
	return touch;
}

/* PARCEL -------------------------------------- */

static Parcel readParcel(FILE *f)
{
	Parcel p;
	p.identification = readIdentification(f);
	int i, n = readInt(f);
	//if( n > MAX_HOLES )
	//	error("Poligono com demasiados buracos");
	p.edge = readRing(f);
	p.nHoles = n;
	p.holes = malloc(n * sizeof(Ring));

	for (i = 0; i < n; i++)
	{
		p.holes[i] = readRing(f); //!! malloc
	}
	return p;
}

static void showHeader(Identification id)
{
	showIdentification(-1, id, 3);
	printf("\n");
}

static void showParcel(int pos, Parcel p, int length)
{
	showIdentification(pos, p.identification, 3);
	showValue(length);
}

bool insideParcel(Coordinates c, Parcel p)
{
	bool inside = insideRectangle(c, p.edge.boundingBox);

	if (inside)
	{
		inside = insideRing(c, p.edge);
		for (int i = 0; i < p.nHoles && inside; i++)
		{
			inside = inside && !insideRing(c, p.holes[i]);
		}
	}

	return inside;
}

bool adjacentParcels(Parcel a, Parcel b)
{
	bool touch = false;
	if (!sameIdentification(a.identification, b.identification, 3))
	{
		touch = adjacentRings(a.edge, b.edge);
		for (int i = 0; i < a.nHoles && !touch; i++)
		{
			touch = adjacentRings(b.edge, a.holes[i]);
		}
		for (int j = 0; j < b.nHoles && !touch; j++)
		{
			touch = adjacentRings(a.edge, b.holes[j]);
		}
	}

	return touch;
}

/* CARTOGRAPHY -------------------------------------- */

int loadCartography(String fileName, Cartography *cartography)
{
	FILE *f;
	int i;
	f = fopen(fileName, "r");
	if (f == NULL)
		error("Impossivel abrir ficheiro");
	int n = readInt(f);
	//if( n > MAX_PARCELS )
	//	error("Demasiadas parcelas no ficheiro");
	*cartography = malloc(n * sizeof(Parcel));
	for (i = 0; i < n; i++)
	{
		(*cartography)[i] = readParcel(f); //TODO malloc
	}
	fclose(f);
	return n;
}

static int findLast(Cartography cartography, int n, int j, Identification id)
{
	for (; j < n; j++)
	{
		if (!sameIdentification(cartography[j].identification, id, 3))
			return j - 1;
	}
	return n - 1;
}

void showCartography(Cartography cartography, int n)
{
	int last;
	Identification header = {"___FREGUESIA___", "___CONCELHO___", "___DISTRITO___"};
	showHeader(header);
	for (int i = 0; i < n; i = last + 1)
	{
		last = findLast(cartography, n, i, cartography[i].identification);
		showParcel(i, cartography[i], last - i + 1);
	}
}

/* INTERPRETER -------------------------------------- */

static bool checkArgs(int arg)
{
	if (arg != -1)
		return true;
	else
	{
		printf("ERRO: FALTAM ARGUMENTOS!\n");
		return false;
	}
}

static bool checkPos(int pos, int n)
{
	if (0 <= pos && pos < n)
		return true;
	else
	{
		printf("ERRO: POSICAO INEXISTENTE!\n");
		return false;
	}
}

// L
static void commandListCartography(Cartography cartography, int n)
{
	showCartography(cartography, n);
}

// M pos
static void commandMaximum(int pos, Cartography cartography, int n)
{
	if (!checkArgs(pos) || !checkPos(pos, n))
		return;

	Identification id = cartography[pos].identification;

	int i = pos;
	Parcel p = cartography[pos];
	int maxVertexes = 0;
	int maxPos = pos;
	Parcel maxParcel;
	while (i < n && sameIdentification(id, cartography[i].identification, 3))
	{
		int m = p.edge.nVertexes;
		for (int j = 0; j < p.nHoles; j++)
		{
			m += p.holes[j].nVertexes;
		}
		if (m > maxVertexes)
		{
			maxVertexes = m;
			maxParcel = p;
			maxPos = i;
		}
		i++;
		p = cartography[i];
	}

	i = pos - 1;
	p = cartography[pos];
	while (i >= 0 && sameIdentification(id, cartography[i].identification, 3))
	{
		int m = p.edge.nVertexes;
		for (int j = 0; j < p.nHoles; j++)
		{
			m += p.holes[j].nVertexes;
		}
		if (m > maxVertexes)
		{
			maxVertexes = m;
			maxParcel = p;
			maxPos = i;
		}
		i--;
		p = cartography[i];
	}
	showParcel(maxPos, maxParcel, maxVertexes);
}

//X
static void commandBoundaries(Cartography cartography, int m)
{

	int nPos = 0,
		ePos = 0,
		sPos = 0,
		wPos = 0;

	double n = cartography[nPos].edge.boundingBox.topLeft.lat,
		   e = cartography[ePos].edge.boundingBox.bottomRight.lon,
		   s = cartography[sPos].edge.boundingBox.bottomRight.lat,
		   w = cartography[wPos].edge.boundingBox.topLeft.lon;

	for (int i = 1; i < m; i++)
	{

		Rectangle auxR = cartography[i].edge.boundingBox;
		if (n < auxR.topLeft.lat)
		{
			nPos = i;
			n = cartography[nPos].edge.boundingBox.topLeft.lat;
		}
		if (e < auxR.bottomRight.lon)
		{
			ePos = i;
			e = cartography[ePos].edge.boundingBox.bottomRight.lon;
		}
		if (s > auxR.bottomRight.lat)
		{
			sPos = i;
			s = cartography[sPos].edge.boundingBox.bottomRight.lat;
		}
		if (w > auxR.topLeft.lon)
		{
			wPos = i;
			w = cartography[wPos].edge.boundingBox.topLeft.lon;
		}
	}

	showParcel(nPos, cartography[nPos], -'N');
	showParcel(ePos, cartography[ePos], -'E');
	showParcel(sPos, cartography[sPos], -'S');
	showParcel(wPos, cartography[wPos], -'W');
}

//R
static void commandParcelInformation(int pos, Cartography cartography, int n)
{
	if (!checkArgs(pos) || !checkPos(pos, n))
		return;

	Parcel parcel = cartography[pos];

	showIdentification(pos, parcel.identification, 3);
	printf("\n%4s ", "");
	printf("%d ", parcel.edge.nVertexes);
	int i = 0;
	while (i < parcel.nHoles)
	{
		printf("%d ", parcel.holes[i].nVertexes);
		i++;
	}
	Rectangle r = parcel.edge.boundingBox;
	showRectangle(r);
	printf("\n");
}

//V
static void commandTrip(double lat, double lon, int pos, Cartography cartography, int n)
{
	if (!checkArgs(lat) || !checkArgs(lon) || !checkArgs(pos) || !checkPos(pos, n))
		return;

	Coordinates auxC = coord(lat, lon);
	double distance = haversine(cartography[pos].edge.vertexes[0], auxC);
	for (int i = 1; i < cartography[pos].edge.nVertexes; i++)
	{
		double d = haversine(cartography[pos].edge.vertexes[i], auxC);
		{
			if (d < distance)
				distance = d;
		}
	}

	printf("%f\n", distance);
}

//Q
static int numberFreguesia(int pos, Identification id, Cartography cartography, int n)
{
	int i = pos;
	int m = 0;

	while (i < n && sameIdentification(id, cartography[i].identification, 3))
	{
		m++;
		i++;
	}
	i = pos - 1;
	while (i > 0 && sameIdentification(id, cartography[i].identification, 3))
	{
		m++;
		i++;
	}
	return m;
}

static int numberConselhosDistritos(Identification id, Cartography cartography, int n, int l)
{
	int i = 0;
	int m = 0;

	for (int i = 0; i < n; i++)
	{
		if (sameIdentification(id, cartography[i].identification, l))
		{
			m++;
		}
	}
	return m;
}

static void commandParcelHowMany(int pos, Cartography cartography, int n)
{
	if (!checkArgs(pos) || !checkPos(pos, n))
		return;

	Parcel p = cartography[pos];
	Identification id = p.identification;
	int nFreguesias = numberFreguesia(pos, id, cartography, n);
	int nConselhos = numberConselhosDistritos(id, cartography, n, 2);
	int nDistritos = numberConselhosDistritos(id, cartography, n, 1);

	showParcel(pos, p, nFreguesias);

	showIdentification(pos, id, 2);
	showValue(nConselhos);

	showIdentification(pos, id, 1);
	showValue(nDistritos);
}

//C
static bool inVector(String s, StringVector v, int n)
{
	bool belongs = false;
	int i = 0;
	while (!belongs && i < n)
	{
		if (strcmp(v[i], s) == 0)
			belongs = true;
		i++;
	}
	return belongs;
}

int cmpstr(void const *a, void const *b)
{
	char const *aa = (char const *)a;
	char const *bb = (char const *)b;

	return strcmp(aa, bb);
}

static void commandConcelhos(Cartography cartography, int n)
{
	StringVector concelhos; //[MAX_STRING_VECTOR];
	int m = 0;
	String c;
	for (int i = 0; i < n; i++)
	{

		strcpy(c, cartography[i].identification.concelho);
		if (!inVector(c, concelhos, m))
		{
			strcpy(concelhos[m], c);
			m++;
		}
	}

	qsort(concelhos, m, MAX_STRING, cmpstr);
	showStringVector(concelhos, m);
}

//D
static void commandDistritos(Cartography cartography, int n)
{
	StringVector distritos;
	int m = 0;
	String d;
	for (int i = 0; i < n; i++)
	{
		strcpy(d, cartography[i].identification.distrito);
		if (!inVector(d, distritos, m))
		{
			strcpy(distritos[m], d);
			m++;
		}
	}

	qsort(distritos, m, MAX_STRING, cmpstr);
	showStringVector(distritos, m);
}

//P
static void commandParcel(double lat, double lon, Cartography cartography, int n)
{
	if (!checkArgs(lat) || !checkArgs(lon))
		return;

	Coordinates c = coord(lat, lon);
	int found = -1;
	int i = 0;

	while (found < 0 && i < n)
	{
		if (insideParcel(c, cartography[i]))
			found = i;
		i++;
	}
	if (found < 0)
	{
		printf("FORA DO MAPA\n");
	}
	else
	{
		showIdentification(found, cartography[found].identification, 3);
		printf("\n");
	}
}

//A
static void commandAdjacencies(int pos, Cartography cartography, int n)
{
	if (!checkArgs(pos) || !checkPos(pos, n))
		return;

	bool m = false;
	
	for (int i = 0; i < n; i++)
	{
		if (adjacentParcels(cartography[pos], cartography[i]))
		{
			showIdentification(i, cartography[i].identification, 3);
			printf("\n");
			m = true;
		}
	}

	if (!m)
	{
		printf("NAO HA ADJACENCIAS\n");
	}
}

//F
static void commandBorders(int pos1, int pos2, Cartography cartography, int n)
{
	if (!checkArgs(pos1) || !checkPos(pos1, n) || !checkArgs(pos2) || !checkPos(pos2, n))
		return;
}

//T
static void commandPartition(int dist, Cartography cartography, int n)
{
	if (!checkArgs(dist))
		return;
}

void interpreter(Cartography cartography, int n)
{
	String commandLine;
	for (;;)
	{ // ciclo infinito
		printf("> ");
		readLine(commandLine, stdin);
		char command = ' ';
		double arg1 = -1.0, arg2 = -1.0, arg3 = -1.0;
		sscanf(commandLine, "%c %lf %lf %lf", &command, &arg1, &arg2, &arg3);
		// printf("%c %lf %lf %lf\n", command, arg1, arg2, arg3);
		switch (commandLine[0])
		{
		case 'L':
		case 'l': // listar
			commandListCartography(cartography, n);
			break;

		case 'M':
		case 'm': // maximo
			commandMaximum(arg1, cartography, n);
			break;

		case 'X':
		case 'x': //extremos
			commandBoundaries(cartography, n);
			break;

		case 'R':
		case 'r': //resumo
			commandParcelInformation(arg1, cartography, n);
			break;

		case 'V':
		case 'v': // viagem
			commandTrip(arg1, arg2, arg3, cartography, n);
			break;

		case 'Q':
		case 'q': // quantos
			commandParcelHowMany(arg1, cartography, n);
			break;

		case 'C':
		case 'c': // conselhos
			commandConcelhos(cartography, n);
			break;

		case 'D':
		case 'd': // distritos
			commandDistritos(cartography, n);
			break;

		case 'P':
		case 'p': // parcela
			commandParcel(arg1, arg2, cartography, n);
			break;

		case 'A':
		case 'a': // adjacencias
			commandAdjacencies(arg1, cartography, n);
			break;

		case 'F':
		case 'f': // fronteiras
			commandBorders(arg1, arg2, cartography, n);
			break;

		case 'T':
		case 't': // particao
			commandPartition(arg1, cartography, n);
			break;

		case 'Z':
		case 'z': // terminar
			printf("Fim de execucao! Volte sempre.\n");
			return;

		default:
			printf("Comando desconhecido: \"%s\"\n", commandLine);
		}
	}
}
