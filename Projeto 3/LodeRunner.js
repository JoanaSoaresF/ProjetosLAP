/*     Lode Runner

01234567890123456789012345678901234567890123456789012345678901234567890123456789
*/

// GLOBAL VARIABLES

// tente não definir mais nenhuma variável global

let empty, hero, control;


// ACTORS

class Actor {
	constructor(x, y, imageName) {
		this.x = x;
		this.y = y;
		this.imageName = imageName;
		this.show();
		//
		this.free = false;  //available to move to
		this.colectable = false;
		this.walkable = 0;
		//
	}
	draw(x, y) {
		control.ctx.drawImage(GameImages[this.imageName],
			x * ACTOR_PIXELS_X, y * ACTOR_PIXELS_Y);
	}

	isFree() {
		return this.free;
	}

	isColectable() {
		return this.colectable;
	}

	isWalkable() {
		return this.walkable === 1;
	}

	isClimbable() {
		return this.walkable === 2;
	}

}

class PassiveActor extends Actor {
	constructor(x, y, imageName) {
		super(x, y, imageName);
	}


	show() {
		control.world[this.x][this.y] = this;
		this.draw(this.x, this.y);
	}
	hide() {
		control.world[this.x][this.y] = empty;
		empty.draw(this.x, this.y);
	}

}

class ActiveActor extends Actor {

	constructor(x, y, imageName) {
		super(x, y, imageName);
		this.time = 0;	// timestamp used in the control of the animations
		this.goldColected = 0;
		this.walkable = 1;
		this.name;
		this.imagesNames = ['_falls_left', '_falls_right',
			'_on_ladder_left', '_on_ladder_right', ' on_rope_left',
			'_on_rope_right', '_runs_left', '_runs_right',
			'_shoots_left', '_shoots_right'];

	}
	show() {
		control.worldActive[this.x][this.y] = this;
		this.draw(this.x, this.y);
	}
	hide() {
		control.worldActive[this.x][this.y] = empty;
		control.world[this.x][this.y].draw(this.x, this.y);
	}
	animation() {
		//TODO aspetos em comum
	}

	move(dx, dy) {
		if (this.canMove(dx, dy)) {
			if (control.world[this.x + dx][this.y + dy].isColectable()) {
				control.world[this.x + dx][this.y + dy].colect();
				this.goldColected += 1;
			}
			this.hide();
			this.x += dx;
			this.y += dy;
			let left = dx < 0;


			if (left) {
				this.turn(6);
			} else {
				this.turn(7);
			}
			this.show();


			//
			if (this.mayFall()) {

				this.fall();
			}
		}
	}



	canMove(dx, dy) {
		return control.world[this.x + dx][this.y + dy].isFree()  //
			&& control.worldActive[this.x + dx][this.y + dy].isFree();
	}
	mayFall() {
		return !(control.world[this.x][this.y + 1].isWalkable()
			|| control.worldActive[this.x][this.y + 1].isWalkable()
			|| control.world[this.x][this.y].isClimbable());
	}
	fall() {
		this.hide();
		this.y += 1;
		if (this.imageName.includes('left'))
			this.turn(0);
		else
			this.turn(1);

		this.show();


		for (let i = 0; i < 1000000000; i++) {
			;
		}
		this.show();
		if (this.mayFall()) { //TODO adicionar condição do sair da tela
			for (let i = 0; i < 1000000000; i++) {
				;
			}
			this.fall();
		} else {
			this.hide();
			if (this.imageName.includes('left'))
				this.turn(6);
			else
				this.turn(7);

			this.show();

		}


	}
	turn(pos) {
		this.imageName = this.name + this.imagesNames[pos];
		this.draw(this.x, this.y)
	}
}

class ColectableActor extends PassiveActor {
	constructor(x, y, imageName) {
		super(x, y, imageName);
		this.free = true;
		this.colectable = true;
	}

	colect() {
		//TODO ver se ja foi coletado
		this.hide();
		//this = empty;
	}
}

class Brick extends PassiveActor {
	constructor(x, y) {
		super(x, y, "brick");
		this.walkable = 1;
	}
}

class Chimney extends PassiveActor {
	constructor(x, y) {
		super(x, y, "chimney");
		this.free = true;
	}
}

class Empty extends PassiveActor {
	constructor() {
		super(-1, -1, "empty");
		this.free = true;
	}
	show() { } //??FIX
	hide() { } //??FIX
}

class Gold extends ColectableActor {
	constructor(x, y) {
		super(x, y, "gold");

	}

}

class Invalid extends PassiveActor {
	constructor(x, y) { super(x, y, "invalid"); }
}

class Ladder extends PassiveActor {
	constructor(x, y) {
		super(x, y, "ladder");
		this.visible = false;
		this.free = true;
		this.walkable = 1;

	}
	show() {
		if (this.visible)
			super.show();
	}
	hide() {
		if (this.visible)
			super.hide();
	}
	makeVisible() {
		this.visible = true;
		this.show();
	}
}

class Rope extends PassiveActor {
	constructor(x, y) {
		super(x, y, "rope");
		this.free = true;
		this.walkable = 2;
	}
}

class Stone extends PassiveActor {
	constructor(x, y) {
		super(x, y, "stone");
		this.walkable = 1;
	}
}

class Hero extends ActiveActor {
	constructor(x, y) {
		super(x, y, "hero_runs_left");
		this.name = 'hero';
	}
	animation() {
		var k = control.getKey();
		if (k == ' ') { alert('SHOOT'); return; }
		if (k == null) return;
		let [dx, dy] = k;
		this.move(dx, dy);

	}

	//TODO: apanhar ouro
	collect() {
		this.goldColected += 1;
	}
	//TODO: disparar
}

class Robot extends ActiveActor {
	constructor(x, y) {
		super(x, y, "robot_runs_right");
		this.dx = 1;
		this.dy = 0;
		this.name = 'robot';

	}
}



// GAME CONTROL

class GameControl {
	constructor() {
		control = this;
		this.key = 0;
		this.time = 0;
		this.ctx = document.getElementById("canvas1").getContext("2d");
		empty = new Empty();	// only one empty actor needed
		this.world = this.createMatrix();
		this.worldActive = this.createMatrix();
		this.loadLevel(1);
		this.setupEvents();
	}
	createMatrix() { // stored by columns
		let matrix = new Array(WORLD_WIDTH);
		for (let x = 0; x < WORLD_WIDTH; x++) {
			let a = new Array(WORLD_HEIGHT);
			for (let y = 0; y < WORLD_HEIGHT; y++)
				a[y] = empty;
			matrix[x] = a;
		}
		return matrix;
	}
	loadLevel(level) {
		if (level < 1 || level > MAPS.length)
			fatalError("Invalid level " + level)
		let map = MAPS[level - 1];  // -1 because levels start at 1
		for (let x = 0; x < WORLD_WIDTH; x++)
			for (let y = 0; y < WORLD_HEIGHT; y++) {
				// x/y reversed because map stored by lines
				GameFactory.actorFromCode(map[y][x], x, y);
			}
	}
	getKey() {
		let k = control.key;
		control.key = 0;
		switch (k) {
			case 37: case 79: case 74: return [-1, 0]; //  LEFT, O, J
			case 38: case 81: case 73: return [0, -1]; //    UP, Q, I
			case 39: case 80: case 76: return [1, 0];  // RIGHT, P, L
			case 40: case 65: case 75: return [0, 1];  //  DOWN, A, K
			case 0: return null;
			default: return String.fromCharCode(k);
			// http://www.cambiaresearch.com/articles/15/javascript-char-codes-key-codes
		};
	}
	setupEvents() {
		addEventListener("keydown", this.keyDownEvent, false);
		addEventListener("keyup", this.keyUpEvent, false);
		setInterval(this.animationEvent, 1000 / ANIMATION_EVENTS_PER_SECOND);
	}
	animationEvent() {
		control.time++;
		for (let x = 0; x < WORLD_WIDTH; x++)
			for (let y = 0; y < WORLD_HEIGHT; y++) {
				let a = control.worldActive[x][y];
				if (a.time < control.time) {
					a.time = control.time;
					a.animation();
				}
			}
	}
	keyDownEvent(k) {
		control.key = k.keyCode;
	}
	keyUpEvent(k) {
	}
}


// HTML FORM

function onLoad() {
	// Asynchronously load the images an then run the game
	GameImages.loadAll(function () { new GameControl(); });
}

function b1() { mesg("button1") } //TODO: botão reset
function b2() { mesg("button2") } //TODO: infromações sobre o jogo



