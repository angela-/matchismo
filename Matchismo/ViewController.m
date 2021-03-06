//
//  ViewController.m
//  Matchismo
//
//  Created by it_admin on 1/15/14.
//  Copyright (c) 2014 hello. All rights reserved.
//

#import "ViewController.h"
#import "UIAlertView+Blocks.h"
#import "HistoryViewController.h"

#import "PlayingCardView.h"
#import "PlayingCard.h"
@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *scoreLabel;

@property (nonatomic, getter = isGameEnded) BOOL gameEnded;
@property (nonatomic, getter = isGameAlreadySaved) BOOL gameAlreadySaved;
@property (strong, nonatomic) NSString *gameName;
@property (nonatomic) NSTimeInterval gameTime;


@property (nonatomic) CGPoint cardPileAnchorPoint;
@property (strong, nonatomic) UIDynamicAnimator *animator;


@end

@implementation ViewController

#pragma mark - lifecyle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.setupNewGame = YES;
    [self setupGestureRecognizers];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.grid.size = self.gameCardsView.frame.size;
    self.grid.cellAspectRatio = [CardView cardViewDefaultAspectRatio];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    
    self.grid.size = self.gameCardsView.frame.size;
    self.grid.cellAspectRatio = [CardView cardViewDefaultAspectRatio];
    self.grid.minimumNumberOfCells = self.cardCount;
    
    [self layoutCardViews];
    
}

#pragma mark - lazy loading

- (CardMatchingGame *)game
{
    if (!_game){
        _game = [[CardMatchingGame alloc] initWithDeck:[self createDeck]];
    }
    return _game;
}

- (NSMutableArray *)cardViews
{
    if (!_cardViews){
        _cardViews = [[NSMutableArray alloc] init];
    }
    return _cardViews;
}

- (Grid *)grid
{
    if (!_grid){
        _grid = [[Grid alloc] init];
    }
    return _grid;
}

- (UIDynamicAnimator *)animator
{
    if (!_animator){
        _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.gameCardsView];
    }
    return _animator;
}

#pragma mark - View Gesture Recognizers

- (void)setupGestureRecognizers
{
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinch:)];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    tap.cancelsTouchesInView = NO;
    
    pinch.delegate = self;
    pan.delegate = self;
    tap.delegate = self;
    
    [self.gameCardsView addGestureRecognizer:pinch];
    [self.gameCardsView addGestureRecognizer:tap];
    [self.gameCardsView addGestureRecognizer:pan];
}

- (void)pinch:(UIPinchGestureRecognizer *)gesture
{
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            self.cardsInPile = YES;
            self.cardPileAnchorPoint = CGPointMake(self.gameCardsView.frame.origin.x + self.gameCardsView.frame.size.width*0.5f, self.gameCardsView.frame.origin.y + self.gameCardsView.frame.size.height*0.5f);
            
            for (CardView *cardView in self.cardViews){
                UIAttachmentBehavior *attachment = [[UIAttachmentBehavior alloc] initWithItem:cardView attachedToAnchor:self.cardPileAnchorPoint];
                [self.animator addBehavior:attachment];
            }
            gesture.scale = 1;
            break;
        case UIGestureRecognizerStateChanged:
            if (gesture.scale > 1){
                gesture.scale = 1;
                return;
            }
            for (UIDynamicBehavior *behavior in self.animator.behaviors){
                if ([behavior isKindOfClass:[UIAttachmentBehavior class]]){
                    UIAttachmentBehavior *attachment = (UIAttachmentBehavior *)behavior;
                    attachment.length *= gesture.scale;
                }
            }
            gesture.scale = 1;
            break;
        default:
            break;
    }
}

- (void)pan:(UIPanGestureRecognizer *)gesture
{
    CGPoint newAnchorPoint = [gesture locationInView:self.gameCardsView];
    for (UIDynamicBehavior *behavior in [self.animator.behaviors reverseObjectEnumerator]){
        if ([behavior isKindOfClass:[UIAttachmentBehavior class]]){
            UIAttachmentBehavior *attachment = (UIAttachmentBehavior *)behavior;
            attachment.anchorPoint = newAnchorPoint;
        }
    }
}

- (void)tap:(UITapGestureRecognizer *)tap
{
    [self.animator removeAllBehaviors];
    [self layoutCardViews];
    self.cardsInPile = NO;
    self.animator = nil;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] || [gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]){
        if (!self.cardsInPile){
            return NO;
        }
    }
    return YES;
}

#pragma mark - Setup Game

- (void)createGameWithCardCount:(NSInteger)cardCount
{
    if ([self.cardViews count]>0){
        [self.cardViews removeAllObjects];
    }
    if ([[self.gameCardsView subviews] count]>0){
        for (UIView *cardView in [self.gameCardsView subviews]){
            [cardView removeFromSuperview];
        }
    }
    self.setupNewGame = YES;
    [self drawNewCards:cardCount];
    self.setupNewGame = NO;
}

- (void)drawNewCards:(NSInteger)numberOfCards
{
    CGRect tempFrame = [self.grid frameOfCellAtRow:0 inColumn:0];
    NSInteger index = [self.cardViews count];
    for (int i =0; i<numberOfCards; i++) {
        //create card views
        CardView *cardView = [self cardViewForCardAtIndex:index++ Frame:tempFrame];
        
        //draw card
        Card *card = [self.game drawNewCard];

//        [self updateView:cardView forCard:card defaultEnable:YES];
        [cardView setCard:card defaultEnable:YES];
        [self.gameCardsView addSubview:cardView];
    }
    
    [self layoutCardViews];
}

- (void)layoutCardViews
{
    int x = 0;
    NSPredicate *inPlayCardsPredicate = [NSPredicate predicateWithFormat:@"self.inPlay == YES"];
    NSArray *cardsInPlay = [self.cardViews filteredArrayUsingPredicate:inPlayCardsPredicate];
    NSInteger cardCount = cardsInPlay.count;
    self.grid.minimumNumberOfCells = cardCount;
    
    for (int i=0; i<self.grid.rowCount; i++){
        for (int j=0; j<self.grid.columnCount; j++){
            x +=1;
            if (x> cardCount){
                break;
            }
            CGRect frame =[self.grid frameOfCellAtRow:i inColumn:j];
            CardView *cardView = cardsInPlay[x-1];
            
            CGFloat delay = 0;
            if (self.setupNewGame){
                delay = x*0.2f;
            }
            
            CGFloat duration = 1.0f;
            if (self.cardsInPile){
                duration = 0.25f;
            }
            
            [UIView animateWithDuration:duration delay:delay options:0 animations:^{
                cardView.frame = frame;
            } completion:^(BOOL finished) {
                [self.gameCardsView sendSubviewToBack:cardView];
                [cardView setNeedsDisplay];
            }];
            
        }
        if (x> cardCount){
            break;
        }
    }
}

#pragma mark - Game Controls

- (IBAction)startNewGame
{
    void (^tapBlock)(UIAlertView *alertView, NSInteger buttonIndex)=^void(UIAlertView *alertView, NSInteger buttonIndex){
        
        if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:ALERT_OK_BUTTON]){
        
            //end timer and save game details
            if (alertView.alertViewStyle == UIAlertViewStylePlainTextInput){
                self.gameName = [[alertView textFieldAtIndex:0] text];
            }
            [self saveGameStatistics];
            
            //reset game
            self.game = nil;
            self.setupNewGame = YES;
            [self game];
            [self createGameWithCardCount:self.cardCount];
            
            //start new game
            [self updateUINewGame];
            [self setGameAlreadySaved:NO];
            [self setGameEnded:NO];
            
            self.scoreLabel.text = [NSString stringWithFormat:@"Score: %i",(int)self.game.score];
        }
    };
    
    NSString *title = @"New Game";
    NSString *message = @"this will END current game and start a NEW game?";
    NSString *placholder = @"enter your name.";
    
    if (self.isGameAlreadySaved){
        [UIAlertView showWithTitle:title
                           message:message
                 cancelButtonTitle:ALERT_CANCEL_BUTTON
                 otherButtonTitles:@[ALERT_OK_BUTTON]
                          tapBlock:tapBlock];
    }else{
        [UIAlertView showWithTitle:title
                           message:message
              textFieldPlaceholder:placholder
                 cancelButtonTitle:ALERT_CANCEL_BUTTON
                 otherButtonTitles:@[ALERT_OK_BUTTON]
                          tapBlock:tapBlock];
    }
}

- (void)updateUINewGame
{
    int i=0;
    for (CardView *cardView in self.cardViews){
        Card  *card = [self.game cardAtIndex:i++];
//        [cardView setCard:card defaultEnable:NO];
        [self updateView:cardView forCard:card defaultEnable:NO];
    }
}

- (IBAction)endCurrentGame:(id)sender
{
    [UIAlertView showWithTitle:@"End Game"
                       message:@"This will end your current game?"
          textFieldPlaceholder:@"Enter your name."
             cancelButtonTitle:ALERT_CANCEL_BUTTON otherButtonTitles:@[ALERT_OK_BUTTON]
                      tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                          if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:ALERT_OK_BUTTON]){
                              
                              self.gameName = [[alertView textFieldAtIndex:0] text];
                              [self saveGameStatistics];
                              [self setGameEnded:YES];
                              
                          }
                          
                      }];
}

- (void)saveGameStatistics
{
    if (self.isGameAlreadySaved){
        return;
    }
    
    [self setGameAlreadySaved:YES];
    self.gameTime = [self.game endGame];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *data = [[defaults objectForKey:SAVE_KEY] mutableCopy];
    NSDictionary *gameData = @{SAVE_KEY_NAME:self.gameName,
                               SAVE_KEY_SCORE:[NSNumber numberWithInt:self.game.score],
                               SAVE_KEY_GAME_TYPE:self.gameType,
                               SAVE_KEY_TIME:[NSNumber numberWithInt:self.gameTime]};
    
    if (data == nil){
        data = [[NSMutableArray alloc] initWithArray:@[gameData]];
    }else{
        [data addObject:gameData];
    }
    [defaults setObject:data forKey:SAVE_KEY];
}

#pragma mark - Game Play
- (void)cardSelected:(id)sender
{
    if (self.isGameEnded || self.waitingForAnimationFinish){
        return;
    }
    
    if (self.cardsInPile){
        [self tap:nil];
        return;
    }
    
    NSUInteger chosenButtonIndex = [self.cardViews indexOfObject:sender];
    self.activeCard =[self.game cardAtIndex:chosenButtonIndex];
    
    if (self.activeCard.matched){
        return;
    }
    
    [self.game chooseCardAtIndex:chosenButtonIndex];
//    [self updateView:(CardView *)sender forCard:self.activeCard defaultEnable:YES];
    [(CardView *)sender setCard:self.activeCard defaultEnable:YES];
    
    switch (self.game.matchStatus) {
        case MatchStatusTypeMatchFound:
        case MatchStatusTypeMatchNotFound:
            [self updateUIMatchDone];
            break;
        default:
            break;
    }
}

- (void)updateView:(CardView *)cardView forCard:(Card *)card defaultEnable:(BOOL)defaultEnable
{
    [cardView setCard:card defaultEnable:defaultEnable];
}

- (void)updateUIMatchDone
{
    self.scoreLabel.text = [NSString stringWithFormat:@"Score: %i",(int)self.game.score];
}

- (void)updateCardsView
{
    self.waitingForAnimationFinish = NO;
    
    for (CardView *cardView in self.cardViews){
        NSUInteger cardViewIndex = [self.cardViews indexOfObject:cardView];
        Card *card = [self.game cardAtIndex:cardViewIndex];
        if (card == self.activeCard && !card.isMatched){
            self.activeCard.chosen = NO;
        }
        [cardView setCard:card defaultEnable:NO];
        //[self updateView:cardView forCard:card defaultEnable:NO];
    }
    self.activeCard = nil;
}


#pragma mark - methods to be overwritten

- (Deck *)createDeck
{
    return nil;
}

- (CardView *)cardViewForCardAtIndex:(NSInteger)index Frame:(CGRect)frame
{
    return nil;
}


@end
