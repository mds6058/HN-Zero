//
//  HNAppDelegate.m
//  HackerNews
//
//  Created by Matthew Stanford on 8/24/13.
//  Copyright (c) 2013 Matthew Stanford. All rights reserved.
//

#import "HNAppDelegate.h"
#import "HNTheme.h"
#import "HNArticleContainerVC.h"
#import "HNMainMenu.h"
#import "HNMenuLink.h"
#import "GAI.h"
#import <MMDrawerController/MMDrawerController.h>
#import "HNSettings.h"
#import "HNArticleListVC.h"
#import "HNWebBrowserVC.h"
#import "HNCommentVC.h"
#import "HNNavigationViewController.h"
#import "HNThemeChanger.h"
#import "HNTheme+Themes.h"

@interface HNAppDelegate ()

@property (strong, nonatomic) HNNavigationViewController *navController;
@property (strong, nonatomic) HNArticleListVC *articleListVC;
@property (strong, nonatomic) HNWebBrowserVC *webBrowserVC;
@property (strong, nonatomic) HNWebBrowserVC *commentWebBrowserVC;
@property (strong, nonatomic) HNCommentVC *commentVC;
@property (strong, nonatomic) HNArticleContainerVC *articleContainerVC;
@property (strong, nonatomic) HNMainMenu *mainMenuVC;
@property (strong, nonatomic) HNDownloadController *downloadController;
@property (strong, nonatomic) HNSettings *settings;

@end

@implementation HNAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Google Analytics
    id<GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:@"UA-49248907-1"];
    
    //Enable URL on-disk caching
    NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:2 * 1024 * 1024
                                                            diskCapacity:100 * 1024 * 1024
                                                                diskPath:nil];
    [NSURLCache setSharedURLCache:sharedCache];
    
    HNTheme *theme = [HNTheme classicTheme];
    [self initializeUIWithTheme:theme];
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void) initializeUIWithTheme:(HNTheme *)theme
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    self.settings = [self getSettings];
    
    self.webBrowserVC = [[HNWebBrowserVC alloc] initWithTheme:theme];
    self.commentWebBrowserVC = [[HNWebBrowserVC alloc] initWithTheme:theme];
    self.downloadController = [[HNDownloadController alloc] init];
    self.downloadController.settings = self.settings;
    
    HNThemeChanger *themeChanger = [[HNThemeChanger alloc] init];
    
    self.commentVC = [[HNCommentVC alloc] initWithTheme:theme
                                             webBrowser:self.commentWebBrowserVC
                                 withDownloadController:self.downloadController
                                            andSettings:self.settings];
    
    self.articleContainerVC = [[HNArticleContainerVC alloc] initWithArticleVC:self.webBrowserVC
                                                                andCommentsVC:self.commentVC];
    
    //[self setupMainMenu];
    NSArray *menuLinks = [self initializeMenuLinks];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        
        //First initialze the drawer controller with its root view controllers
        UIViewController *splitVC = [[UISplitViewController alloc] init];
        UISplitViewController *splitVCptr;
        splitVCptr = (UISplitViewController *)splitVC;
        splitVCptr.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
        
        self.mainMenuVC = [[HNMainMenu alloc]
                           initWithStyle:UITableViewStyleGrouped
                           withTheme:theme
                           withArticleVC:nil
                           withMenuLinks:menuLinks
                           andSettings:self.settings];
        
        MMDrawerController *drawerController = [self setupDrawerControllerWithCenterVC:splitVC
                                                                                leftVC:self.mainMenuVC];
        
        self.articleListVC = [[HNArticleListVC alloc] initWithStyle:UITableViewStylePlain
                                                   withWebBrowserVC:self.webBrowserVC
                                                       andCommentVC:self.commentVC
                                                   articleContainer:self.articleContainerVC
                                                          withTheme:theme
                                               withDrawerController:drawerController
                                             withDownloadController:self.downloadController
                                                        andSettings:self.settings];
        
        //Finish setting up the main menu VC
        self.mainMenuVC.articleListVC = self.articleListVC;        
        
        //[self setupMainMenuWithLinks:menuLinks withArticleListVC:self.articleListVC];
        
        //Initialze the splitVC and finish initiazing the rest of the UI
        HNNavigationViewController *articleListNavController = [[HNNavigationViewController alloc] initWithRootViewController:self.articleListVC];
        
        [themeChanger addThemedViewController:articleListNavController];
        
        HNNavigationViewController *articleContainerNavController = [[HNNavigationViewController alloc] initWithRootViewController:self.articleContainerVC];
        
        [themeChanger addThemedViewController:articleContainerNavController];
        
        NSArray *splitVCArray = [NSArray arrayWithObjects:articleListNavController, articleContainerNavController, nil];
        [(UISplitViewController *)splitVC setViewControllers:splitVCArray];
        
        splitVC.view.backgroundColor = [UIColor lightGrayColor];
        self.articleContainerVC.splitVC = splitVC;
        
        [self.window setRootViewController:drawerController];
    }
    else
    {
        self.articleListVC = [[HNArticleListVC alloc] initWithStyle:UITableViewStylePlain
                                                   withWebBrowserVC:self.webBrowserVC
                                                       andCommentVC:self.commentVC
                                                   articleContainer:self.articleContainerVC
                                                          withTheme:theme
                                             withDownloadController:self.downloadController
                                                        andSettings:self.settings];
        
        
        self.mainMenuVC = [[HNMainMenu alloc] initWithStyle:UITableViewStyleGrouped
                                                  withTheme:theme
                                              withArticleVC:self.articleListVC
                                              withMenuLinks:menuLinks
                                                andSettings:self.settings];
        
        [self setupMainMenuWithLinks:menuLinks
                   withArticleListVC:self.articleListVC
                           withTheme:theme];
        
        self.navController = [[HNNavigationViewController alloc] initWithRootViewController:self.mainMenuVC];
        
        
        [themeChanger addThemedViewController:self.navController];
        
        [self.window setRootViewController:self.navController];
        
    }
    
    [self.mainMenuVC changeMenuLink:[menuLinks objectAtIndex:0]];

    
    [themeChanger addThemedViewController:self.articleListVC];
    [themeChanger addThemedViewController:self.commentVC];
    [themeChanger addThemedViewController:self.webBrowserVC];
    [themeChanger addThemedViewController:self.commentWebBrowserVC];
    [themeChanger addThemedViewController:self.mainMenuVC];

    themeChanger.themes = @[[HNTheme classicTheme], [HNTheme darkTheme]];
    [themeChanger loadSavedTheme];

    self.mainMenuVC.themeChanger = themeChanger;
    
    
    self.window.backgroundColor = [UIColor whiteColor];
}

-(HNSettings *)getSettings
{
    HNSettings *settings;
    HNSettings *cachedSettings = [HNSettings getCachedSettings];
    if (cachedSettings)
    {
        settings = cachedSettings;
    }
    else
    {
        settings = [[HNSettings alloc] init];
        settings.doPreLoadComments = TRUE;
    }
    
    return settings;
}

-(void) setupMainMenuWithLinks:(NSArray *)menuLinks withArticleListVC:(HNArticleListVC *)articleList withTheme:(HNTheme *)theme
{
    self.mainMenuVC = [[HNMainMenu alloc] initWithStyle:UITableViewStyleGrouped
                                              withTheme:theme
                                          withArticleVC:articleList
                                          withMenuLinks:menuLinks
                                            andSettings:self.settings];
}

-(MMDrawerController *) setupDrawerControllerWithCenterVC:(UIViewController *)centerVC leftVC:(UIViewController *)leftVC
{
    MMDrawerController *drawerController = [[MMDrawerController alloc] initWithCenterViewController:centerVC leftDrawerViewController:leftVC];
    [drawerController setRestorationIdentifier:@"MMDrawer"];
    [drawerController setMaximumRightDrawerWidth:100.0];
    [drawerController setOpenDrawerGestureModeMask:MMOpenDrawerGestureModeAll];
    [drawerController setCloseDrawerGestureModeMask:MMCloseDrawerGestureModeAll];
    
    return drawerController;
    
}

- (NSArray *) initializeMenuLinks
{
    NSString *urlBase = @"https://hacker-news.firebaseio.com/v0";
    NSArray *menuLinks = nil;
    
    HNMenuLink *frontPage = [[HNMenuLink alloc] init];
    frontPage.title = @"Front Page";
    //frontPage.url = [NSURL URLWithString:@"https://news.ycombinator.com"];
    NSString *frontPageUrlString = [NSString stringWithFormat:@"%@/topstories", urlBase];
    frontPage.url = [NSURL URLWithString:frontPageUrlString];
    
    HNMenuLink *askHN = [[HNMenuLink alloc] init];
    askHN.title = @"Ask HN";
    NSString *askUrlString = [NSString stringWithFormat:@"%@/askstories", urlBase];
    askHN.url = [NSURL URLWithString:askUrlString];
    
    HNMenuLink *showHN = [[HNMenuLink alloc] init];
    showHN.title = @"Show HN";
    NSString *showUrlString = [NSString stringWithFormat:@"%@/showstories", urlBase];
    showHN.url = [NSURL URLWithString:showUrlString];
    
    HNMenuLink *jobsHN = [[HNMenuLink alloc] init];
    jobsHN.title = @"Jobs";
    NSString *jobsUrlString = [NSString stringWithFormat:@"%@/jobstories", urlBase];
    jobsHN.url = [NSURL URLWithString:jobsUrlString];
    
    HNMenuLink *newHN = [[HNMenuLink alloc] init];
    newHN.title = @"New";
    NSString *newUrlString = [NSString stringWithFormat:@"%@/newstories", urlBase];
    newHN.url = [NSURL URLWithString:newUrlString];
    
    menuLinks = [[NSArray alloc] initWithObjects:frontPage, askHN, showHN, jobsHN, newHN, nil];
    //menuLinks = [[NSArray alloc] initWithObjects:frontPage, nil];

    
    return menuLinks;
}

@end
