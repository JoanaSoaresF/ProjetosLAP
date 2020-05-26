/*     Lode Runner

01234567890123456789012345678901234567890123456789012345678901234567890123456789
*/

// GLOBAL VARIABLES

// tente não definir mais nenhuma variável global

let empty, hero, control;
const ASCENDABLE = 4;
const FLOOR = 1;
const CLIMBABLE = 2;
const VOID = 0;

// ACTORS

class Actor {
	constructor(x, y, imageName) {
		this.x = x;
		this.y = y;
		this.imageName = imageName;
		this.show();
		//
		this.free = false;  //available to move to
		this.destructible = false;
		this.walkableType = VOID;
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

	isWalkable() {
		return this.walkableType === FLOOR || this.walkableType === ASCENDABLE;
	}

	isClimbable() {
		return this.walkableType === CLIMBABLE;
	}

	isAscendable() {
		return this.walkableType === ASCENDABLE;
	}
	isDestructible() {
		return this.destructible;
	}
	isEnemy() {
		return this.evil;
	}


}

class PassiveActor extends Actor {
	constructor(x, y, imageName) {
		super(x, y, imageName);
		this.trap = false;
	}


	show() {
		control.world[this.x][this.y] = this;
		this.draw(this.x, this.y);
	}
	hide() {
		control.world[this.x][this.y] = empty;
		empty.draw(this.x, this.y);
	}

	getShot() { //in case new personas added can be shotted
		if (this.isDestructible()) { //TODO não destrói se houver outro por cima
			this.hide();
			this.trap = true;
			setTimeout(this.restore.bind(this), 10000);
		}
	}
	isTrap() {
		return this.trap;
	}

	restore() {
		if ((control.worldActive[this.x][this.y] instanceof ActiveActor)) {
			control.worldActive[this.x][this.y].jumpBrick();
		}
		this.trap = false;
		this.show();
	}




}

class ActiveActor extends Actor {

	constructor(x, y, imageName) {
		super(x, y, imageName);
		this.time = 0;	// timestamp used in the control of the animations
		this.goldCollected = 0;
		this.walkableType = FLOOR;
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
	animation() {
		let direction = this.imageName.includes('left');

		if (control.world[this.x][this.y] instanceof CollectableActor) {
			control.world[this.x][this.y].collect();
			this.show();
			this.collectGold();
		}

		if (this.mayFall()) {
			this.hide();
			this.turn(0, direction);
			this.show();
			this.fall(direction);
		}
	}

	evalCollision(dx, dy) {
		//TODO condição de sair para fora da tela
		if (!(control.worldActive[this.x + dx][this.y + dy] instanceof Empty)
			&& ((!this.isEnemy()
				&& control.worldActive[this.x + dx][this.y + dy].isEnemy()) //hero colide robot
				|| (this.isEnemy()
					&& !control.worldActive[this.x + dx][this.y + dy].isEnemy()))) { //robot colide hero

			hero.die();
		}

	}
	//Covers the common actions of animation of the ative actors
	move(dx, dy) {
		this.evalCollision(dx, dy);
		if (this.canMove(dx, dy)) {
			this.hide();
			this.x += dx;
			this.y += dy;
			let left = (dx === 0) ? this.imageName.includes('left') : dx < 0;

			this.turn(6, left);
			this.show();
		}

	}
	collectGold() {
		this.goldCollected += 1;
	}

	canMove(dx, dy) {
		return (this.x + dx < WORLD_WIDTH) && (this.x + dx >= 0) //in the canvas
			&& control.world[this.x + dx][this.y + dy].isFree() //the new position is free
			&& (dy >= 0 || control.world[this.x][this.y].isAscendable()) // can go up only when on a ladder
			&& (control.world[this.x][this.y].isClimbable() // can't move during a fall
				|| control.world[this.x][this.y + 1].isWalkable()
				|| control.worldActive[this.x][this.y + 1].isWalkable());
	}
	mayFall() {
		return this.y + 1 < WORLD_HEIGHT && !(control.world[this.x][this.y + 1].isWalkable()
			|| control.worldActive[this.x][this.y + 1].isWalkable()
			|| control.world[this.x][this.y].isClimbable()
			|| control.world[this.x][this.y].isAscendable());
	}
	fall(left) {
		this.hide();
		this.y += 1;
		this.show();

		if (!this.mayFall()) {
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
	jumpBrick() {
		this.y -= 1;
		this.show();
	}
}

class CollectableActor extends PassiveActor {
	constructor(x, y, imageName) {
		super(x, y, imageName);
		this.free = true;
	}

	collect() {
		this.hide();
	}
}

class EvilActiveActor extends ActiveActor {
	constructor(x, y, imageName) {
		super(x, y, imageName);
		this.dx = 1;
		this.dy = 0;
		this.evil = true;
		this.free = true; //the hero and the robot have to colide
		this.hX = 0;
		this.hY = 0;
		this.trapped = false;
	}

	findHero() {
		/*	for (let yHPos = 0; yHPos < WORLD_HEIGHT; yHPos++) {
				for (let xHPos = 0; xHPos < WORLD_WIDTH; xHPos++) {
					if (control.worldActive[xHPos][yHPos] instanceof ActiveActor)
						if (!control.worldActive[xHPos][yHPos].isEnemy()) {
							this.hX = control.worldActive[xHPos][yHPos].x;
							this.hY = control.worldActive[xHPos][yHPos].y;
						}
				}
			}*/
		this.hX = hero.x;
		this.hY = hero.y;
	}

	collectGold() {
		if (this.goldCollected < 1) {
			super.collectGold();
		}

	}
	canMove(dx, dy) {
		return super.canMove(dx, dy)
			&& !(control.worldActive[this.x + dx][this.y + dy].isEnemy());

	}
	animation() {
		//TODO cair no buraco sem cair
		//TODO largar ouro ao cair no buraco
		if (!control.world[this.x][this.y].isTrap()) {
			if (!super.animation()) {
				this.findHero();
				if (this.hY < this.y && this.canMove(0, -1))
					this.move(0, -1);
				else if (this.hY > this.y && this.canMove(0, 1))
					this.move(0, 1);
				else if (this.hX < this.x && this.canMove(-1, 0))
					this.move(-1, 0);
				else if (this.canMove(1, 0))
					this.move(1, 0);
			}
		}
	}

}

class Brick extends PassiveActor {
	constructor(x, y) {
		super(x, y, "brick");
		this.walkableType = FLOOR;
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
		super(x, y, "empty");
		this.free = true;
		this.walkableType = ASCENDABLE;
	}
	makeVisible() {
		this.imageName = "ladder";
		this.show();
	}
}

class Rope extends PassiveActor {
	constructor(x, y) {
		super(x, y, "rope");
		this.free = true;
		this.walkableType = CLIMBABLE;
	}
}

class Stone extends PassiveActor {
	constructor(x, y) {
		super(x, y, "stone");
		this.walkableType = FLOOR;
	}
}

class Hero extends ActiveActor {
	constructor(x, y) {
		super(x, y, "hero_runs_left");
		this.name = 'hero';
	}

	isAllGoldCollected() {
		return this.goldCollected >= 1;
	}

	collectGold() {
		super.collectGold();
		if (this.isAllGoldCollected()) { //all gold collected
			control.showEscapeLadder();
		}
	}

	animation() {
		super.animation();
		if (this.y + 1 >= WORLD_HEIGHT) { //fall to the void
			this.die();
		} else if (control.worldActive[this.x][this.y].isEnemy()) { //colide with robot
			this.die();
		}

		var k = control.getKey();
		if (k == ' ') {
			let direction = this.imageName.includes('left') ? -1 : 1
			this.shot(direction); return;
		}

		if (k == null) return;
		let [dx, dy] = k;

		if (this.isAllGoldCollected() && this.y + dy < 0) { //level up
			this.win();
		} else {

			this.move(dx, dy);

		}
	}

	win() {
		//hero.hide();
		mesg('Subida de Nível!');
		let level = control.currentLevel + 1;
		canvas1.width = canvas1.width;
		setTimeout(onLoad, 5, level);

	}
	die() {

		setTimeout(mesg, 10, "Morreu, tente novamente");
		let level = control.currentLevel;
		let clear = function () {
			canvas1.width = canvas1.width;
			onLoad(level);

		}
		setTimeout(clear, 500, level);

	}


	shot(direction) {
		if (control.world[this.x][this.y].isFree()
			&& control.world[this.x][this.y + 1].isWalkable()) {
			this.turn(8, (direction === -1));
			control.world[this.x + direction][this.y + 1].getShot();
			//TODO recuo
			if (control.world[this.x - direction][this.y].isFree())
				this.move(-direction, 0);

		}




	}

}


class Robot extends EvilActiveActor {
	constructor(x, y) {
		super(x, y, "robot_runs_right");
		this.counter = 0;
		this.name = 'robot';

	}
	animation() {
		//TODO como gerar movimento do robot
		//this.move(dx, dy);
		this.counter++;
		if (control.time % 8 === 0) //?? usar o time
			super.animation();

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
	showEscapeLadder() {
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



