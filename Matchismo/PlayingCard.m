//
//  PlayingCard.m
//  Matchismo
//
//  Created by it_admin on 1/15/14.
//  Copyright (c) 2014 hello. All rights reserved.
//

#import "PlayingCard.h"

@interface PlayingCard ()
+ (NSArray *)rankStrings;
@end

@implementation PlayingCard

@synthesize suit = _suit;//synthesize when both setter & getter are provided

+ (NSArray *)validSuits
{
    return @[@"♥",@"♦",@"♠",@"♣"];
}

+ (NSArray *)rankStrings
{
    return @[@"?",@"A",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9",@"10",@"J",@"Q",@"K"];
}

+(NSUInteger)maxRank
{
    return [[self rankStrings] count] -1;
}

-(NSString *)contents
{
    NSArray *rankStrings = [PlayingCard rankStrings];
    return [rankStrings[self.rank] stringByAppendingString:self.suit];
}

-(int)match:(NSArray *)otherCards
{
    int score = 0;
    
    //compare card against other cards
    for (PlayingCard *otherCard in otherCards){
        if (otherCard.rank == self.rank){
            score += 4;
        }else if ([otherCard.suit isEqualToString:self.suit]){
            score += 1;
        }
    }
    
    //for 3 card implementation
    if (otherCards.count == 2){
        score += [otherCards[0] match:@[otherCards[1]]];
    }
    
    return score;
}


-(NSString *) suit
{
    return _suit ? _suit:@"?";
}

-(void)setSuit:(NSString*)suit
{
    if ([[PlayingCard validSuits] containsObject:suit]){
        _suit = suit;
    }
}

-(void)setRank:(NSUInteger)rank
{
    if (rank<= [PlayingCard maxRank]){
        _rank = rank;
    }
}



@end
