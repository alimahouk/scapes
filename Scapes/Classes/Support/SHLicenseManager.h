//
//  SHLicenseManager.h
//  Scapes
//
//  Created by MachOSX on 11/2/13.
//
//

#import <StoreKit/StoreKit.h>
UIKIT_EXTERN NSString *const IAPHelperProductPurchasedNotification;
@class SHLocationManager;

@protocol SHLicenseManagerDelegate<NSObject>
@optional

- (void)licenseManagerDidMakePurchase;
- (void)licenseManagerPurchaseFailed;

@end

@interface SHLicenseManager : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (nonatomic, weak) id <SHLicenseManagerDelegate> delegate;
@property (nonatomic, strong) SKProductsRequest *productsRequest;
@property (nonatomic, strong) SKProduct *SHBDProduct;
@property (nonatomic, strong) RequestProductsCompletionHandler completionHandler;
@property (nonatomic, strong) NSSet *productIdentifiers;
@property (nonatomic, strong) NSMutableSet *purchasedProductIdentifiers;

+ (SHLicenseManager *)sharedInstance;
- (id)initWithProductIdentifiers:(NSSet *)productIdentifiers;
- (void)requestProductsWithCompletionHandler:(RequestProductsCompletionHandler)completionHandler;
- (void)buyProduct;
- (BOOL)productPurchased:(NSString *)productIdentifier;

@end
