//
//  Route.m
//  CircleGame
//
//  Created by Joanne Dyer on 1/19/13.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//

#import "Route.h"
#import "GameConfig.h"

@interface Route ()

//light stays on route when occupied, array should never be empty.
@property (nonatomic, strong) GameLayer *gameLayer;
@property (nonatomic, strong) NSMutableArray *twoDimensionalLightArray;
@property (nonatomic, strong) NSMutableArray *lightsInRoute;

@end

@implementation Route

@synthesize gameLayer = _gameLayer;
@synthesize twoDimensionalLightArray = _twoDimensionalLightArray;
@synthesize lightsInRoute = _lightsInRoute;

- (id)initWithGameLayer:(GameLayer *)gameLayer lightArray:(NSMutableArray *)lightArray
{
    if (self = [super init]) {
        self.gameLayer = gameLayer;
        [self.gameLayer addChild:self];
        self.twoDimensionalLightArray = lightArray;
        self.lightsInRoute = [NSMutableArray array];
        
        //add self as listener to the light on cooldown notifcication.
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(lightOnCooldownEventHandler:)
         name:NOTIFICATION_LIGHT_ON_COOLDOWN
         object:nil];
    }
    return self;
}

//handles the events sent by lights when they enter cooldown and so need to be removed from the route.
- (void)lightOnCooldownEventHandler:(NSNotification *)notification
{
    Light *light = (Light *)notification.object;
    [self removeLightAndAllFollowingFromRoute:light];
}

//used by game layer at the beginning of the game to add the light the player is initially sat in to the route.
- (void)setInitialLight:(Light *)light
{
    [self.lightsInRoute addObject:light];
    light.isPartOfRoute = YES;
}

//called by game layer when a light has been touched, either removed it from route or tries to add it.
- (void)lightSelected:(Light *)light
{
    //if light is in route remove it and all the lights following it. Otherwise add light to route if possible.
    if ([self.lightsInRoute containsObject:light]) {
        [self removeLightAndAllFollowingFromRoute:light];
    } else {
        //Check if a route between this light and the current last light in the route is viable. If yes, add all the between to the route and note which direction the route goes.
        BOOL viableRoute = NO;
        NSMutableArray *lightsToAddToRoute = [NSMutableArray array];
        
        //first check if the light is either directly horizontal or directly vertical from the last light in the route.
        Light *lastLightInRoute = [self.lightsInRoute lastObject];
        
        //get direction between lights.
        Direction routeDirection = [self getDirectionBetweenFirstLight:lastLightInRoute andSecondLight:light];

        //If route direction is left or right go through each light in the columns between the light and the last light in the route checking if they are in the correct state. If route direction is up or down, go through rows.
        if (routeDirection == Right) {
            viableRoute = YES;
            //get inner array for the relevant row.
            NSMutableArray *innerArray = [self.twoDimensionalLightArray objectAtIndex:light.gridLocation.row];
            for (int column = lastLightInRoute.gridLocation.column + 1; column <= light.gridLocation.column; column++) {
                //get light for the relevant column.
                Light *lightAtLocation = [innerArray objectAtIndex:column];
                
                //if the light is in the correct state to be routed add it to the array of lights to add, else break the loop as no lights will be added.
                if ([lightAtLocation canAddLightToRoute]) {
                    [lightsToAddToRoute addObject:lightAtLocation];
                } else {
                    viableRoute = NO;
                    break;
                }
            }
        } else if (routeDirection == Left) {
            viableRoute = YES;
            //get inner array for the relevant row.
            NSMutableArray *innerArray = [self.twoDimensionalLightArray objectAtIndex:light.gridLocation.row];
            for (int column = lastLightInRoute.gridLocation.column - 1; column >= light.gridLocation.column; column--) {
                //get light for the relevant column.
                Light *lightAtLocation = [innerArray objectAtIndex:column];
                
                //if the light is in the correct state to be routed add it to the array of lights to add, else break the loop as no lights will be added.
                if ([lightAtLocation canAddLightToRoute]) {
                    [lightsToAddToRoute addObject:lightAtLocation];
                } else {
                    viableRoute = NO;
                    break;
                }
            }
        } else if (routeDirection == Up) {
            viableRoute = YES;
            for (int row = lastLightInRoute.gridLocation.row + 1; row <= light.gridLocation.row; row++) {
                //get light for the relevant row.
                NSMutableArray *innerArray = [self.twoDimensionalLightArray objectAtIndex:row];
                Light *lightAtLocation = [innerArray objectAtIndex:light.gridLocation.column];
                
                //if the light is in the correct state to be routed add it to the array of lights to add, else break the loop as no lights will be added.
                if ([lightAtLocation canAddLightToRoute]) {
                    [lightsToAddToRoute addObject:lightAtLocation];
                } else {
                    viableRoute = NO;
                    break;
                }
            }
        } else if (routeDirection == Down) {
            viableRoute = YES;
            for (int row = lastLightInRoute.gridLocation.row - 1; row >= light.gridLocation.row; row--) {
                //get light for the relevant row.
                NSMutableArray *innerArray = [self.twoDimensionalLightArray objectAtIndex:row];
                Light *lightAtLocation = [innerArray objectAtIndex:light.gridLocation.column];
                
                //if the light is in the correct state to be routed add it to the array of lights to add, else break the loop as no lights will be added.
                if ([lightAtLocation canAddLightToRoute]) {
                    [lightsToAddToRoute addObject:lightAtLocation];
                } else {
                    viableRoute = NO;
                    break;
                }
            }
        }
        
        //if the route ended up being viable, add all the of the lights between the provided light and the last light in the array to the route and set up their connectors.
        if (viableRoute) {
            [self.lightsInRoute addObjectsFromArray:lightsToAddToRoute];
            int numberOfNewLights = lightsToAddToRoute.count;
            for (int i = 0; i < numberOfNewLights; i++) {
                Light *lightAtIndex = [lightsToAddToRoute objectAtIndex:i];
                lightAtIndex.isPartOfRoute = YES;
                switch (routeDirection) {
                    case Up:
                        lastLightInRoute.topConnector.state = Routed;
                        if (i < numberOfNewLights - 1) lightAtIndex.topConnector.state = Routed;
                        break;
                    case Down:
                        lightAtIndex.topConnector.state = Routed;
                        break;
                    case Left:
                        lightAtIndex.rightConnector.state = Routed;
                        break;
                    case Right:
                        lastLightInRoute.rightConnector.state = Routed;
                        if (i < numberOfNewLights - 1) lightAtIndex.rightConnector.state = Routed;
                        break;
                    default:
                        break;
                }
            }
        }
    }
}

//used by player to get the second light in the route so it can travel to it. (The first light will be the one it is already at.)
- (Light *)getNextLightFromRoute
{
    Light *nextLight;
    if (self.lightsInRoute.count >= 2) {
        nextLight = [self.lightsInRoute objectAtIndex:1];
    } else {
        nextLight = nil;
    }
    return nextLight;
    //TODO make sure player changes this to occupied.
}

//used by player when it starts moving to the next light in the route from the first.
- (void)removeFirstLightFromRoute
{
    if (self.lightsInRoute.count >= 1) {
        Light *firstLight = [self.lightsInRoute objectAtIndex:0];
        firstLight.isPartOfRoute = NO;
        
        //update connector states.
        if (self.lightsInRoute.count >= 2) {
            Light *secondLight = [self.lightsInRoute objectAtIndex:1];
            Direction routeDirection = [self getDirectionBetweenFirstLight:firstLight andSecondLight:secondLight];
            switch (routeDirection) {
                case Up:
                    firstLight.topConnector.state = Enabled;
                    break;
                case Down:
                    secondLight.topConnector.state = Enabled;
                    break;
                case Left:
                    secondLight.rightConnector.state = Enabled;
                    break;
                case Right:
                    firstLight.rightConnector.state = Enabled;
                    break;
                default:
                    break;
            }
        }
        
        [self.lightsInRoute removeObjectAtIndex:0];
        //TODO does this move the other objects along?
        //TODO make sure player changes light to unoccupied.
    }
}

//used when a touch removes part of the route or a light goes on to cooldown.
- (void)removeLightAndAllFollowingFromRoute:(Light *)light
{
    //if light is in route remove it and all the lights following it. Set each light as no longer part of the route.
    if ([self.lightsInRoute containsObject:light]) {
        int lightIndex = [self.lightsInRoute indexOfObject:light];
        
        //update connectors of previous light.
        if (lightIndex >= 1) {
            Light *previousLight = [self.lightsInRoute objectAtIndex:lightIndex - 1];
            Light *light = [self.lightsInRoute objectAtIndex:lightIndex];
            Direction routeDirection = [self getDirectionBetweenFirstLight:previousLight andSecondLight:light];
            if (routeDirection == Up) {
                previousLight.topConnector.state = Enabled;
            } else if (routeDirection == Right) {
                previousLight.rightConnector.state = Enabled;
            }
        
            //go through lights to remove and set them as not part of a route and update their connectors.
            int arrayLength = self.lightsInRoute.count;
            for (int i = lightIndex; i < arrayLength; i++) {
                Light *currentLight = [self.lightsInRoute objectAtIndex:i];
                currentLight.isPartOfRoute = NO;
                currentLight.topConnector.state = Enabled;
                currentLight.rightConnector.state = Enabled;
            }
            NSRange rangeOfIndices = {lightIndex, arrayLength - lightIndex};
            [self.lightsInRoute removeObjectsInRange:rangeOfIndices];
        }
    }
}

//gets direction between two lights (up, down, left, right) to help with routing.
- (Direction)getDirectionBetweenFirstLight:(Light *)firstLight andSecondLight:(Light *)secondLight
{
    Direction direction = None;
    BOOL rowsAreEqual = (secondLight.gridLocation.row == firstLight.gridLocation.row);
    BOOL columnsAreEqual = (secondLight.gridLocation.column == firstLight.gridLocation.column);
    
    if (rowsAreEqual) {
        if (firstLight.gridLocation.column < secondLight.gridLocation.column) {
            direction = Right;
        } else {
            direction = Left;
        }
    } else if (columnsAreEqual) {
        if (firstLight.gridLocation.row < secondLight.gridLocation.row) {
            direction = Up;
        } else {
            direction = Down;
        }
    }
    return direction;
}

@end