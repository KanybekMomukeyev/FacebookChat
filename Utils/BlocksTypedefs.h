/* type defenition for blocks, can be used by any app class */
typedef void (^CompletionBlock)(id, NSError *);
typedef void (^ComplexBlock)(id, id, id);
typedef void (^SimpleBlock)(void);
typedef void (^InfoBlock)(id);
typedef void (^ConfirmationBlock)(BOOL);
typedef BOOL (^BoolBlock)(id);
typedef void (^DownloadProgressBlock)(NSUInteger bytesRead, long long totalBytes, long long totalBytesExp);