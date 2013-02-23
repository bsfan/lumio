//
//  InGameMenuLayer.m
//  CircleGame
//
//  Created by Joanne Dyer on 1/26/13.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//

#import "InGameMenuLayer.h"
#import "BaseMenuLayer.h"
#import "GameLayer.h"
#import "GameConfig.h"
#import "GameKitHelper.h"

@interface InGameMenuLayer ()

@property (nonatomic) BOOL gameOver;

@end

@implementation InGameMenuLayer

@synthesize gameOver = _gameOver;

- (id)init
{
    if( (self=[super init]) ) {
        
        // ask director for the window size
        CGSize size = [[CCDirector sharedDirector] winSize];
        
        CCSprite *background;
        
        if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ) {
            background = [CCSprite spriteWithFile:@"InGameMenuBackground.png"];
            //background.rotation = 90;
        } else {
            background = [CCSprite spriteWithFile:@"InGameMenuBackground.png"];
        }
        background.position = ccp(size.width/2, size.height/2);
        
        // add the background as a child to this Layer
        [self addChild: background z:0];
        
        self.isTouchEnabled = YES;
	}
	return self;
}

- (id)initForPauseMenu
{
    if (self = [self init]) {
        [self setUpMenuWithGameOver:NO score:0];
    }
    return self;
}

- (id)initForGameOverMenuWithScore:(int)score
{
    if (self = [self init]) {
        [self setUpMenuWithGameOver:YES score:score];
    }
    return self;
}

//TODO NEED TO FIX THIS SO IT WORKS OUT IF THE HIGH SCORE WAS LOADED CORRECTLY AND IF IT IS A NEW HIGH SCORE.
- (void)setUpMenuWithGameOver:(BOOL)gameOver score:(int)score
{
    self.gameOver = gameOver;
    
    //get the old high score if possible and see if this score beats it.
    GameKitHelper *helper = [GameKitHelper sharedGameKitHelper];
    int64_t highScore = helper.highScore;
    BOOL isNewHighScore = NO;
    if (helper.highScoreFetchedOK && (int64_t)score > highScore) {
        //store the new high score. The high score will only be loaded from game center the first time.
        isNewHighScore = YES;
        highScore = (int64_t)score;
        helper.highScore = highScore;
    }
    
    //TODO change this to show score and if it's a new high score or the current high score.
    //add game over sprite if game over is true.
    if (self.gameOver) {
        CCSprite *gameOverSprite = [CCSprite spriteWithFile:@"GameOver.png"];
        gameOverSprite.position = ccp(55, 440);
        gameOverSprite.anchorPoint = ccp(0, 1);
        [self addChild: gameOverSprite z:1];
    }
    
    //Create the Resume Menu Item.
    CCMenuItemImage *resumeMenuItem = [CCMenuItemImage
                                itemWithNormalImage:@"ResumeButton.png" selectedImage:@"ResumeButtonSelected.png"
                                target:self selector:@selector(resumeButtonTapped:)];
    resumeMenuItem.anchorPoint = ccp(0, 1);
    resumeMenuItem.position = ccp(49, 410);
    
    //Create the Restart Menu Item.
    CCMenuItemImage *restartMenuItem = [CCMenuItemImage
                                  itemWithNormalImage:@"RestartButton.png" selectedImage:@"RestartButtonSelected.png"
                                  target:self selector:@selector(restartButtonTapped:)];
    restartMenuItem.anchorPoint = ccp(0, 1);
    
    //Change the position based on whether it is a game over screen.
    if (self.gameOver) {
        restartMenuItem.position = ccp(130, 350);
    } else {
        restartMenuItem.position = ccp(140, 333);
    }
    
    //Create the 'Main Menu' Menu Item.
    CCMenuItem *mainMenuMenuItem = [CCMenuItemImage
                                   itemWithNormalImage:@"MenuButton.png" selectedImage:@"MenuButtonSelected.png"
                                   target:self selector:@selector(mainMenuButtonTapped:)];
    mainMenuMenuItem.anchorPoint = ccp(0, 1);
    
    //Change the position based on whether it is a game over screen.
    if (self.gameOver) {
        mainMenuMenuItem.position = ccp(55, 210);
    } else {
        mainMenuMenuItem.position = ccp(45, 197);            
    }

    //Only add resumeMenuItem it is not a game over screen.
    CCMenu *inGameMenu;
    if (self.gameOver) {
        inGameMenu = [CCMenu menuWithItems:restartMenuItem, mainMenuMenuItem, nil];
    } else {
        inGameMenu = [CCMenu menuWithItems:resumeMenuItem, restartMenuItem, mainMenuMenuItem, nil];
    }
    inGameMenu.position = CGPointZero;
    [self addChild:inGameMenu];
}

//prevent touches going to over layers.
- (void)registerWithTouchDispatcher
{
	[[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    return YES;
}

- (void)resumeButtonTapped:(id)sender
{
    GameLayer *gameLayer = (GameLayer *)[[[CCDirector sharedDirector] runningScene] getChildByTag:GAME_LAYER_TAG];
    [gameLayer unPauseGame];
    [self removeFromParentAndCleanup:YES];
}

- (void)restartButtonTapped:(id)sender
{
    GameLayer *gameLayer = (GameLayer *)[[[CCDirector sharedDirector] runningScene] getChildByTag:GAME_LAYER_TAG];
    [gameLayer restartGame];
    [self removeFromParentAndCleanup:YES];
}

- (void)mainMenuButtonTapped:(id)sender
{
    //remove the pause layer but do not unpause the game and push the menu scene. The new scene should only be provided the current scene if continue should be displayed (because it is not game over).
    [self removeFromParentAndCleanup:YES];
    CCScene *currentScene = [[CCDirector sharedDirector] runningScene];
    if (self.gameOver) {
        [[CCDirector sharedDirector] pushScene:[CCTransitionFade transitionWithDuration:0.6 scene:[BaseMenuLayer scene] withColor:ccBLACK]];
    } else {
        [[CCDirector sharedDirector] pushScene:[CCTransitionFade transitionWithDuration:0.6 scene:[BaseMenuLayer sceneWithPreviousScene:currentScene] withColor:ccBLACK]];
    }
}

//TODO saving game and opening on main menu i guess (not pause screen).

@end