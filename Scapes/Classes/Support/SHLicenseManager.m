//
//  SHLicenseManager.m
//  Scapes
//
//  Created by MachOSX on 11/2/13.
//  TUTORIAL: http://www.raywenderlich.com/21081/
//

#import "SHLicenseManager.h"

@implementation SHLicenseManager

- (id)initWithProductIdentifiers:(NSSet *)productIdentifiers
{
    if ( (self = [super init]) )
    {
        // Store product identifiers.
        _productIdentifiers = productIdentifiers;
        
        // Check for previously purchased products.
        _purchasedProductIdentifiers = [NSMutableSet set];
        
        for ( NSString *productIdentifier in _productIdentifiers )
        {
            BOOL productPurchased = [[NSUserDefaults standardUserDefaults] boolForKey:productIdentifier];
            
            if ( productPurchased )
            {
                [_purchasedProductIdentifiers addObject:productIdentifier];
                NSLog(@"Previously purchased: %@", productIdentifier);
            }
            else
            {
                NSLog(@"Not purchased: %@", productIdentifier);
            }
        }
        
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    
    return self;
}

+ (SHLicenseManager *)sharedInstance
{
    static dispatch_once_t once;
    static SHLicenseManager *sharedInstance;
    dispatch_once(&once, ^{
        // The list of in-app purchase identifiers.
        NSSet *productIdentifiers = [NSSet setWithObjects:
                                     @"com.scapehouse.Scapes_full_license",
                                     nil];
        sharedInstance = [[self alloc] initWithProductIdentifiers:productIdentifiers];
    });
    
    return sharedInstance;
}

- (void)requestProductsWithCompletionHandler:(RequestProductsCompletionHandler)completionHandler
{
    _completionHandler = [completionHandler copy];
    
    _productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:_productIdentifiers];
    _productsRequest.delegate = self;
    [_productsRequest start];
}

- (BOOL)productPurchased:(NSString *)productIdentifier
{
    return [_purchasedProductIdentifiers containsObject:productIdentifier];
}

- (void)buyProduct
{
    NSLog(@"Buying %@...", _SHBDProduct.productIdentifier);
    
    SKPayment *payment = [SKPayment paymentWithProduct:_SHBDProduct];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction
{
    NSLog(@"completeTransaction...");
    
    [self provideContentForProductIdentifier:transaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction
{
    NSLog(@"restoreTransaction...");
    
    [self provideContentForProductIdentifier:transaction.originalTransaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction
{
    NSLog(@"failedTransaction...");
    
    if ( transaction.error.code != SKErrorPaymentCancelled )
    {
        NSLog(@"Transaction error: %@", transaction.error.localizedDescription);
    }
    
    [self licenseManagerPurchaseFailed];
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

- (void)provideContentForProductIdentifier:(NSString *)productIdentifier
{
    [_purchasedProductIdentifiers addObject:productIdentifier];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:SHLicenseAnnual] forKey:@"SHBDLicenseType"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self licenseManagerDidMakePurchase];
}

#pragma mark -
#pragma mark SKProductsRequestDelegate methods

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    NSLog(@"Loaded list of products...");
    _productsRequest = nil;
    
    NSArray *skProducts = response.products;
    
    for (SKProduct *skProduct in skProducts)
    {
        _SHBDProduct = skProduct;
        NSLog(@"Found product: %@ %@ %0.2f",
              skProduct.productIdentifier,
              skProduct.localizedTitle,
              skProduct.price.floatValue);
    }
    
    _completionHandler(YES, skProducts);
    _completionHandler = nil;
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"Failed to load list of products. Error: %@", error);
    _productsRequest = nil;
    
    _completionHandler(NO, nil);
    _completionHandler = nil;
}

#pragma mark -
#pragma mark SKPaymentTransactionObserver methods

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for ( SKPaymentTransaction *transaction in transactions )
    {
        switch ( transaction.transactionState )
        {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
                
            default:
                break;
        }
    };
}

#pragma mark -
#pragma mark LicenseManagerDelegate methods

- (void)licenseManagerDidMakePurchase
{
    if ( [_delegate respondsToSelector:@selector(licenseManagerDidMakePurchase)] )
    {
        [_delegate licenseManagerDidMakePurchase];
    }
}

- (void)licenseManagerPurchaseFailed
{
    if ( [_delegate respondsToSelector:@selector(licenseManagerPurchaseFailed)] )
    {
        [_delegate licenseManagerPurchaseFailed];
    }
}

@end
