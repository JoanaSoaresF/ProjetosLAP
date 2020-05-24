/*     Lode Runner

01234567890123456789012345678901234567890123456789012345678901234567890123456789
*/

// GLOBAL VARIABLES

// tente não definir mais nenhuma variável global

let empty, hero, control;

function sleep(milliseconds) {
	var d1 = new Date();
	var start = d1.getTime();
	for (var i = 0; i < 1e7; i++) {
		var d2 = new Date();
		var n = d2.getTime();
		if ((n - start) > milliseconds) {
			break;
		}
	}
}


// ACTORS

class Actor {
	constructor(x, y, imageName) {
		this.x = x;
		this.y = y;
		this.imageName = imageName;
		this.show();
		//
		this.free = false;  //available to move to
		this.collectable = false;
		this.destructible = false;
		this.walkable = 0;
		this.evil = false;
		//
	}
	draw(x, y) {
		control.ctx.drawImage(GameImages[this.imageName],
			x * ACTOR_PIXELS_X, y * ACTOR_PIXELS_Y);
	}

	isFree() {
		return this.free;
	}

	isCollectable() {
		return this.collectable;
	}

	isWalkable() {
		return this.walkable === 1 || this.walkable === 4;
	}

	isClimbable() {
		return this.walkable === 2;
	}

	isAscendable() {
		return this.walkable === 4;
	}
	isDestructible() {
		return this.destructible;
	}
	isEnemy() {
		return this.evil;
	}
	getShot() { //?? classe com coisas sobre as quais se pode disparar?
		if (this.isDestructible()) {
			this.hide();
			setTimeout(this.restore.bind(this), 10000);
		}

	}

	restore() {
		if(!(control.worldActive[this.x][this.y] instanceof ActiveActor)) {
			this.show();
		}

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
		this.goldCollected = 0;
		this.walkable = 1;
		this.name;
		this.imagesNames = ['_falls_left', '_falls_right',
			'_on_ladder_left', '_on_ladder_right', '_on_rope_left',
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

	/**Covers the common actions of animation of the ative actors*/
	move(dx, dy) {
		if (this.canMove(dx, dy)) {
			if (control.world[this.x + dx][this.y + dy].isCollectable()) {
				control.world[this.x + dx][this.y + dy].collect();
				this.goldCollected += 1;
			}
			this.hide();
			this.x += dx;
			this.y += dy;
			let left = (dx === 0) ? this.imageName.includes('left') : dx < 0;

			this.turn(6, left);
			this.show();

			if (this.mayFall()) {
				this.hide();
				this.turn(0, left);
				this.show();
				this.fall(left);
				//setTimeout(this.fall.bind(this), 100, left);
			}
		}

		if (control.world[this.x][this.y].isCollectable()) {
			control.world[this.x + dx][this.y + dy].collect();
			this.goldCollected += 1;
		}
	}

	canMove(dx, dy) { //FIXME corrigir saltar
		return (this.x + dx < WORLD_WIDTH) && (this.x + dx >= 0)
			&& control.world[this.x + dx][this.y + dy].isFree()
			&& control.worldActive[this.x + dx][this.y + dy].isFree();
	}
	mayFall() {
		return this.y + 1 < WORLD_HEIGHT && !(control.world[this.x][this.y + 1].isWalkable()
			|| control.worldActive[this.x][this.y + 1].isWalkable()
			|| control.world[this.x][this.y].isClimbable()
			|| control.world[this.x][this.y].isAscendable());
	}
	fall(left) { //BUG quedas enquanto se está a carregar nas setas
		this.hide();
		this.y += 1;
		this.show();

		if (this.mayFall()) {
			setTimeout(this.fall.bind(this), 100, left);

		} else {
			this.turn(6, left);
			this.show();
		}


	}
	turn(pos, isLeftDirection) {
		let direction = isLeftDirection ? 0 : 1;

		if (control.world[this.x][this.y].isAscendable()) {
			this.imageName = this.name + this.imagesNames[2 + direction];

		} else if (control.world[this.x][this.y].isClimbable()) {
			this.imageName = this.name + this.imagesNames[4 + direction];
		} else {
			this.imageName = this.name + this.imagesNames[pos + direction];
		}
		this.draw(this.x, this.y)
	}
}

class CollectableActor extends PassiveActor {
	constructor(x, y, imageName) {
		super(x, y, imageName);
		this.free = true;
		this.collectable = true;
	}

	collect() {
		this.hide();
	}
}

class Brick extends PassiveActor {
	constructor(x, y) {
		super(x, y, "brick");
		this.walkable = 1;
		this.destructible = true;
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

class Gold extends CollectableActor {
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
		this.walkable = 4;

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
	canMove(dx, dy) {
		let move = super.canMove(dx, dy)
		if (move && control.worldActive[this.x + dx][this.y + dy].isEnemy()) {
			this.die();
		};
		return move;
	}

	animation() {
		var k = control.getKey();

		if (k == ' ') {
			let direction = this.imageName.includes('left') ? -1 : 1
			this.shot(direction); return;
		}

		if (k == null) return;
		let [dx, dy] = k;

		if (this.y + dy < 0) { //level up
			this.win();
		} else {

			this.move(dx, dy);

			if (this.goldCollected === 1) {
				control.showEscapeLadder();
			}

			if (this.y + 1 >= WORLD_HEIGHT) { //fall to the void
				this.die();
			} else if (control.worldActive[this.x][this.y].isEnemy()) { //colide with robot
				this.die();
			}

		}



	}

	win() {
		//hero.hide();
		mesg('Subida de Nível!');
		let level = control.currentLevel +1;
		canvas1.width = canvas1.width;
		setTimeout(onLoad, 5, level);

	}
	die() {
		
		setTimeout(mesg,10, "Morreu, tente novamente");
		let level = control.currentLevel;
		let clear = function(){
			canvas1.width = canvas1.width;
			onLoad(level);

		}
		setTimeout(clear, 500, level);
	
	}


	shot(direction) {
		this.turn(8, (direction === -1));
		control.world[this.x + direction][this.y + 1].getShot();

	}
	collect() { //?? aqui ou no ator ativo?
		this.goldCollected += 1;
	}

}

class Robot extends ActiveActor {
	constructor(x, y) {
		super(x, y, "robot_runs_right");
		this.dx = 1;
		this.dy = 0;
		this.evil = true;
		this.free = true; //the hero and the robot have to colide

		this.name = 'robot';

	}
	animation() {
		//TODO como gerar movimento do robot
		//this.move(dx, dy);

	}
}



// GAME CONTROL

class GameControl {
	constructor(level) {
		control = this;
		this.key = 0;
		this.time = 0;
		this.currentLevel = level;
		this.totalGold = 0;
		this.escapeLadder = new Array();
		this.ctx = document.getElementById("canvas1").getContext("2d");
		empty = new Empty();	// only one empty actor needed
		this.world = this.createMatrix();
		this.worldActive = this.createMatrix();
		this.loadLevel(this.currentLevel);
		this.setupEvents();



	}
	showEscapeLadder() { //FIXME heroi desaparece a subir a escada
		for (let i = 0; i < this.escapeLadder.length; i++) {
			let x = this.escapeLadder[i][0];
			let y = this.escapeLadder[i][1];
			GameFactory.actorFromCode('e', x, y);
		}

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
				if (map[y][x] === 'o') {
					control.totalGold++;
				}
				if (map[y][x] === 'E') {
					control.escapeLadder.push([x, y]);
				}
			}
	}
	getKey() {//!NÃO MEXER
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
	setupEvents() {//!NÃO MEXER
		addEventListener("keydown", this.keyDownEvent, false);
		addEventListener("keyup", this.keyUpEvent, false);
		setInterval(this.animationEvent, 1000 / ANIMATION_EVENTS_PER_SECOND);
	}
	animationEvent() {//!NÃO MEXER
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
	keyDownEvent(k) {//!NÃO MEXER
		control.key = k.keyCode;
	}
	keyUpEvent(k) { //!NÃO MEXER
	}
}


// HTML FORM

function onLoad(level) {
	// Asynchronously load the images an then run the game
	GameImages.loadAll(function () { new GameControl(level); });
}

function b1() { mesg("button1") } //TODO: botão reset
function b2() { mesg("button2") } //TODO: informações sobre o jogo



