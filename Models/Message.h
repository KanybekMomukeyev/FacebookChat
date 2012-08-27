@interface Message : NSManagedObject {
    BOOL messageStatus;
}

@property (nonatomic, retain) NSDate *sentDate;
@property (nonatomic, retain) NSNumber *read;
@property (nonatomic, retain) NSString *text;
@property (nonatomic, assign) BOOL messageStatus;
@end
