/*     Lode Runner

01234567890123456789012345678901234567890123456789012345678901234567890123456789
*/

// GLOBAL VARIABLES

// tente não definir mais nenhuma variável global
let animation;
let empty, hero, control, gameHistory;
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
		this.walkableType = VOID;
		this.evil = false;
		//
		//this.gameNumber = control.gameNumber;
	}
	draw(x, y) {
		control.ctx.drawImage(GameImages[this.imageName],
			x * ACTOR_PIXELS_X, y * ACTOR_PIXELS_Y);
	}

	isFree() {
		return this.free;
	}

	isWalkable() {
		return this.walkableType === FLOOR
			|| this.walkableType === ASCENDABLE;
	}

	isClimbable() {
		return this.walkableType === CLIMBABLE;
	}

	isAscendable() {
		return this.walkableType === ASCENDABLE;
	}

	isEnemy() {
		return this.evil;
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

	isDestructible() {
		return this instanceof PassiveActorShootable;
	}

	animation() { }
}

class PassiveActorShootable extends PassiveActor {

	constructor(x, y, imageName) {
		super(x, y, imageName);
		this.timeToRestore = 250;
	}

	hide() {
		this.imageName = "empty";
		this.walkableType = VOID;
		this.free = true;
		this.show();
	}


	getShot() { //in case new personas added can be shotted
		if (control.world[this.x][this.y - 1].isFree()) {
			this.hide();
			gameHistory.traps.push([this.x, this.y, 100]);
		}
	}
	restore() {

		if ((control.worldActive[this.x][this.y] instanceof ActiveActor)) {
			control.worldActive[this.x][this.y].jumpBrick();
		} else {
			gameHistory.traps.shift();
		}
		this.free = false;
		this.timeToRestore = 250;
		this.walkableType = FLOOR;
		this.imageName = "brick";
		this.show();
	}

	animation() {
		for (let i = 0; i < gameHistory.traps.length; i++) {
			let time = gameHistory.traps[i][2];
			let x = gameHistory.traps[i][0];
			let y = gameHistory.traps[i][1];

			if (time <= 0) {
				control.world[x][y].restore();
			}
			if (this.x === x && this.y === y) {
				gameHistory.traps[i][2] -= 1;

			}

			/*if (this.timeToRestore <= 0)
				this.restore();
			else
				this.timeToRestore--;*/
		}
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
		if (this.mayFall()) {
			this.hide();
			this.turn(0, direction);
			this.show();
			this.fall(direction);
			return false;
		}
		return true;
	}
	insideBorders(dx, dy) {
		return this.x + dx >= 0 && this.x + dx < WORLD_WIDTH
			&& this.y + dy >= 0 && this.y + dy < WORLD_WIDTH;
	}

	evalCollision(dx, dy) {

		if (this.insideBorders(dx, dy)
			&& !(control.worldActive[this.x + dx][this.y + dy] instanceof Empty)) {

			if (!this.isEnemy() //hero colides with robot
				&& control.worldActive[this.x + dx][this.y + dy].isEnemy()) {
				this.die()
			} else if (this.isEnemy() //robot colides with hero
				&& !control.worldActive[this.x + dx][this.y + dy].isEnemy()) {
				control.worldActive[this.x + dx][this.y + dy].die();
			}
		}
	}


	//Covers the common actions of animation of the ative actors
	move(dx, dy) {
		if (this.insideBorders(dx, dy)
			&& control.world[this.x + dx][this.y + dy] instanceof CollectableActor) {
			if (this.collectGold()) {
				control.world[this.x + dx][this.y + dy].collect();
			}
		}
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
		return true;
	}

	canMove(dx, dy) {
		return (this.x + dx < WORLD_WIDTH) && (this.x + dx >= 0
			&& this.y + dy < WORLD_HEIGHT) //in the canvas
			&& (this.y + dy >= 0 && control.world[this.x + dx][this.y + dy].isFree()) //the new position is free
			&& (dy >= 0 || control.world[this.x][this.y].isAscendable()) // can go up only when on a ladder
			&& (control.world[this.x][this.y].isClimbable() // can't move during a fall
				|| (this.y + 1 === WORLD_HEIGHT) // can walk on the borders	
				|| control.world[this.x][this.y + 1].isWalkable()
				|| control.worldActive[this.x][this.y + 1].isWalkable()
				|| control.world[this.x][this.y].isAscendable());
	}

	mayFall() {
		return this.y + 1 < WORLD_HEIGHT && !(control.world[this.x][this.y + 1].isWalkable()
			|| control.worldActive[this.x][this.y + 1].isWalkable()
			|| control.world[this.x][this.y].isClimbable()
			|| control.world[this.x][this.y].isAscendable());
	}

	fall(left) {

		if (this.insideBorders(0, 1)
			&& control.world[this.x][this.y + 1] instanceof CollectableActor) {
			if (this.collectGold()) {
				control.world[this.x][this.y + 1].collect();
			}
		}
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
		if (control.worldActive[this.x][this.y - 1] instanceof Empty
			&& control.world[this.x][this.y] instanceof PassiveActorShootable) {
			this.y -= 1;
			control.worldActive[this.x][this.y + 1] = empty;
			this.show();
		} else { //robot dies because it can't get out and reborns after 5 units of time
			control.world[this.x][this.y].timeToRestore = 5;
		}
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
		this.movCounter = 0;
		this.evil = true;
		this.free = true; //the hero and the robot have to colide
		this.hX = 0;
		this.hY = 0;

	}

	findHero() {

		this.hX = hero.x;
		this.hY = hero.y;
	}

	collectGold() {
		if (this.goldCollected < 1) {
			super.collectGold();
			this.movCounter = 0;
			return true;
		}
		return false;

	}
	canMove(dx, dy) {
		return super.canMove(dx, dy)
			&& !(control.worldActive[this.x + dx][this.y + dy].isEnemy());

	}
	isTrapped() {
		let found = false;
		for (let i = 0; i < gameHistory.traps.length && !found; i++) {
			if (gameHistory.traps[i][0] == this.x
				&& gameHistory.traps[i][1] == this.y) {
				found = true;

				if (this.goldCollected > 0) {
					this.goldCollected--;
					GameFactory.actorFromCode('o', this.x, this.y - 1); //??
				}
			}
		}
		return found;
	}

	dropGold(dx) {
		if (this.goldCollected > 0
			&& (this.y + 1 === WORLD_HEIGHT ||
				control.world[this.x][this.y + 1].walkableType === FLOOR)
			&& !(control.world[this.x - dx][this.y].isAscendable() ||
				control.world[this.x - dx][this.y].isClimbable())) {
			this.goldCollected = 0;
			GameFactory.actorFromCode('o', this.x - dx, this.y); //??
		}

	}

	move(dx, dy) {
		super.move(dx, dy);
		if (this.movCounter > 5) {
			this.dropGold(dx);
			this.movCounter = 0;
		}
		if (this.goldCollected > 0)
			this.movCounter++;
	}

	animation() {

		if (!this.isTrapped()) {
			if (super.animation()) {
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
		} else {
			gameHistory.bonusScore(2);
		}
	}
}

class Brick extends PassiveActorShootable {
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
	show() { }
	hide() { }
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
		this.walkableType = VOID;
	}

	makeVisible() {
		this.walkableType = ASCENDABLE;
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
		return this.goldCollected >= gameHistory.totalLevelGold;
	}

	collectGold() {
		super.collectGold();
		this.show();
		gameHistory.bonusScore(200);
		if (this.isAllGoldCollected()) {
			gameHistory.showEscapeLadder();
		}
		return true;
	}

	animation() {
		super.animation();

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
		gameHistory.levelUp();
	}
	die() {
		gameHistory.die();
	}


	shot(direction) {
		if (control.world[this.x][this.y].isFree()
			&& this.y + 1 != WORLD_HEIGHT
			&& control.world[this.x][this.y + 1].isWalkable()) {

			this.turn(8, (direction === -1)); //shot position

			if (this.insideBorders(direction, 0)
				&& control.world[this.x + direction][this.y + 1].isDestructible()) {

				control.world[this.x + direction][this.y + 1].getShot(); //shot
			}

			if (this.insideBorders(-direction, 0)
				&& control.world[this.x - direction][this.y].isFree()) //gun's recoil
				this.move(-direction, 0);

			this.turn(8, (direction === -1));
		}
	}
}


class Robot extends EvilActiveActor {
	constructor(x, y) {
		super(x, y, "robot_runs_right");
		this.name = 'robot';

	}
	animation() {
		if (control.time % 5 === 0) {
			super.animation();
		}
	}
}

// GAME CONTROL
class GameInfo {
	constructor() {
		this.lives = 5;
		this.score = 0;
		this.maxScore = 0;
		this.currentLevel = 1;
		this.traps = new Array();
		this.totalLevelGold = 0;
		this.escapeLadder = new Array();
	}

	loseLife() {
		this.lives--;

	}

	bonusLife() {
		this.lives++;
	}

	computeScore() {
		this.score += Math.floor(100000 * this.currentLevel / hero.time);
		drawScore();
		this.updateMaxScore();
	}

	bonusScore(bonus) {
		this.score += Math.floor(bonus * this.currentLevel / 2);
		drawScore();
		this.updateMaxScore();

	}

	updateMaxScore() {
		if (this.score > this.maxScore) {
			this.maxScore = this.score;
		}
	}

	showEscapeLadder() {
		for (let i = 0; i < this.escapeLadder.length; i++) {
			let x = this.escapeLadder[i][0];
			let y = this.escapeLadder[i][1];
			//GameFactory.actorFromCode('e', x, y);
			control.world[x][y].makeVisible();
		}
	}

	die() {
		this.loseLife();
		if (this.lives > 0) {
			let msg = "You died, try again. Level: " + this.currentLevel + "\n Lives remaining: " + this.lives;
			gameHistory.score -= Math.floor(hero.goldCollected * 200 * this.currentLevel / 2 + (100 * this.currentLevel));
			if (this.score < 0) {
				this.score = 0;
			}
			setTimeout(mesg, 0, msg);
			setTimeout(reset, 100, this.currentLevel);
		} else {
			setTimeout(mesg, 0, "You died and you don't have any more lives.\n Restart at level 1!");
			gameHistory.score = 0;
			this.lives = 5;
			setTimeout(reset, 100, 1);
		}
		drawScore();
	}

	levelUp() {
		let level = this.currentLevel + 1;
		if (level < MAPS.length) {
			setTimeout(mesg, 0, 'Subida de Nível! Nível: ' + level);
			setTimeout(reset, 5, level);
			this.bonusLife();
			this.computeScore();
		} else {
			endGame();
		}


	}
}

class GameControl {
	constructor(level) {
		control = this;
		this.key = 0;
		this.time = 0;
		gameHistory = new GameInfo();
		this.ctx = document.getElementById("canvas1").getContext("2d");
		empty = new Empty();	// only one empty actor needed
		this.world = this.createMatrix();
		this.worldActive = this.createMatrix();
		this.loadLevel(gameHistory.currentLevel);
		this.setupEvents();
		drawScore();
	}


	clear() {
		//this.ctx.clearRect(0, 0, WORLD_WIDTH, WORLD_HEIGHT);
		this.ctx.canvas.width = this.ctx.canvas.width;
		this.world = this.createMatrix();
		this.worldActive = this.createMatrix();

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
					gameHistory.totalLevelGold++;
				}
				if (map[y][x] === 'E') {
					gameHistory.escapeLadder.push([x, y]);
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
		animation = setInterval(this.animationEvent, 1000 / ANIMATION_EVENTS_PER_SECOND);
	}
	animationEvent() {//!NÃO MEXER
		control.time++;

		for (let x = 0; x < WORLD_WIDTH; x++) {
			for (let y = 0; y < WORLD_HEIGHT; y++) {
				let a = control.worldActive[x][y];
				let b = control.world[x][y];
				b.animation();
				if (a.time < control.time) {
					a.time = control.time;
					a.animation();
				}
			}
		}
	}
	keyDownEvent(k) {//!NÃO MEXER
		control.key = k.keyCode;
	}
	keyUpEvent(k) { //!NÃO MEXER
	}
}
function reset(level) {
	control.key = 0;
	//control.time = 0;
	gameHistory.currentLevel = level;
	gameHistory.totalLevelGold = 0;
	gameHistory.escapeLadder = new Array();
	gameHistory.traps = new Array();
	control.clear();
	control.loadLevel(level);
	drawScore();
}

// HTML FORM

function endGame() {
	control.ctx.clearRect(0, 0, canvas1.width, canvas1.height);
	control.ctx.font = "30px Arial";
	control.ctx.fillText("Jogo Terminado. Parabéns!", 50, canvas1.height / 2);
	//control = null;
	clearInterval(animation);

}

function onLoad(level) {
	// Asynchronously load the images an then run the game
	GameImages.loadAll(function () { new GameControl(level); });
}



function b1() {
	let level = gameHistory.currentLevel;
	gameHistory.lives--;
	reset(level);
	mesg("Restart level " + level)
}

function drawScore() {
	let element = document.getElementById("info");
	let element2 = document.getElementById("level");
	element.innerHTML = "Score: " + gameHistory.score +
		"     Lives: " + gameHistory.lives +
		"     Gold: " + hero.goldCollected + " from " + gameHistory.totalLevelGold;
	element2.innerHTML = "Level: " + gameHistory.currentLevel;

}
function b2() {
	let time = "Time: " + control.time + ".\n";
	let lives = "Lives remaining: " + gameHistory.lives + ".\n";
	let score = "Total Score: " + gameHistory.score + ".\n";
	let level = "Level: " + gameHistory.currentLevel + ".\n";
	let gold = "Gold Collected: " + hero.goldCollected + " from "
		+ gameHistory.totalLevelGold + " golds.\n"
	let maxScore = "Maximum Score: " + gameHistory.maxScore;
	let msg = time + level + gold + lives + score + maxScore;
	mesg(msg)
} 



