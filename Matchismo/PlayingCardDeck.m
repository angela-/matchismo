//
//  PlayingCardDeck.m
//  Matchismo
//
//  Created by it_admin on 1/15/14.
//  Copyright (c) 2014 hello. All rights reserved.
//

#import "PlayingCardDeck.h"
#import "PlayingCard.h"

@implementation PlayingCardDeck

+ (NSInteger)totalNumberOfCards
{
    return 52;
}

-(instancetype)init
{
    self = [super init];
    if (self){
        for (NSString *suit in [PlayingCard validSuits]){
            for (NSUInteger rank =1; rank <= [PlayingCard maxRank]; rank ++){
                PlayingCard *card = [[PlayingCard alloc] init];
                card.rank = rank;
                card.suit = suit;
                [self addCard:card];
            }
        }
        self.numberOfCardsMatchMode = 2;
    }
    return self;
}

@end
