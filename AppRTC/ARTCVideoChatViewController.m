//
//  ARTCVideoChatViewController.m
//  AppRTC
//
//  Created by Kelly Chu on 3/7/15.
//  Copyright (c) 2015 ISBX. All rights reserved.
//

#import "ARTCVideoChatViewController.h"
#import <AVFoundation/AVFoundation.h>

#define SERVER_HOST_URL @"https://apprtc.appspot.com"

@implementation ARTCVideoChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.isZoom = NO;
    self.isAudioMute = NO;
    self.isVideoMute = NO;
    
    [self.audioButton.layer setCornerRadius:20.0f];
    [self.videoButton.layer setCornerRadius:20.0f];
    [self.hangupButton.layer setCornerRadius:20.0f];
    
    //Add Tap to hide/show controls
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleButtonContainer)];
    [tapGestureRecognizer setNumberOfTapsRequired:1];
    [self.view addGestureRecognizer:tapGestureRecognizer];
    
    //Add Double Tap to zoom
    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(zoomRemote)];
    [tapGestureRecognizer setNumberOfTapsRequired:2];
    [self.view addGestureRecognizer:tapGestureRecognizer];
    

    //Getting Orientation change
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:@"UIDeviceOrientationDidChangeNotification"
                                               object:nil];
    
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[self navigationController] setNavigationBarHidden:YES animated:YES];
    
    //Display the Local View full screen while connecting to Room
    [self.localViewBottomConstraint setConstant:0.0f];
    [self.localViewRightConstraint setConstant:0.0f];
    [self.localViewHeightConstraint setConstant:self.view.frame.size.height];
    [self.localViewWidthConstraint setConstant:self.view.frame.size.width];
    [self.footerViewBottomConstraint setConstant:0.0f];
    
    //Connect to the room
    [self disconnect];
    self.client = [[ARDAppClient alloc] initWithDelegate:self];
    [self.client setServerHostUrl:SERVER_HOST_URL];
    [self.client connectToRoomWithId:self.roomName options:nil];
    
    [self.urlLabel setText:self.roomUrl];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    [self disconnect];
}

- (void)applicationWillResignActive:(UIApplication*)application {
    [self disconnect];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)orientationChanged:(NSNotification *)notification{
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)setRoomName:(NSString *)roomName {
    _roomName = roomName;
    self.roomUrl = [NSString stringWithFormat:@"%@/r/%@", SERVER_HOST_URL, roomName];
}

- (void)disconnect {
    if (self.client) {
        [self.client disconnect];
    }
}

- (void)remoteDisconnected {
    
}

- (void)toggleButtonContainer {
    [UIView animateWithDuration:0.3f animations:^{
        if (self.buttonContainerViewLeftConstraint.constant <= -40.0f) {
            [self.buttonContainerViewLeftConstraint setConstant:20.0f];
            [self.buttonContainerView setAlpha:1.0f];
        } else {
            [self.buttonContainerViewLeftConstraint setConstant:-40.0f];
            [self.buttonContainerView setAlpha:0.0f];
        }
        [self.view layoutIfNeeded];
    }];
}

- (void)zoomRemote {
    //Toggle Aspect Fill or Fit
    self.isZoom = !self.isZoom;
}

- (IBAction)audioButtonPressed:(id)sender {
    //TODO: this change not work on simulator (it will crash)
    UIButton *audioButton = sender;
    if (self.isAudioMute) {
        [self.client unmuteAudioIn];
        [audioButton setImage:[UIImage imageNamed:@"audioOn"] forState:UIControlStateNormal];
        self.isAudioMute = NO;
    } else {
        [self.client muteAudioIn];
        [audioButton setImage:[UIImage imageNamed:@"audioOff"] forState:UIControlStateNormal];
        self.isAudioMute = YES;
    }
}

- (IBAction)videoButtonPressed:(id)sender {
    UIButton *videoButton = sender;
    if (self.isVideoMute) {
//        [self.client unmuteVideoIn];
        [self.client swapCameraToFront];
        [videoButton setImage:[UIImage imageNamed:@"videoOn"] forState:UIControlStateNormal];
        self.isVideoMute = NO;
    } else {
        [self.client swapCameraToBack];
        //[self.client muteVideoIn];
        //[videoButton setImage:[UIImage imageNamed:@"videoOff"] forState:UIControlStateNormal];
        self.isVideoMute = YES;
    }
}

- (IBAction)hangupButtonPressed:(id)sender {
    //Clean up
    [self disconnect];
    [self.navigationController popToRootViewControllerAnimated:YES];
}


#pragma mark - ARDAppClientDelegate

- (void)appClient:(ARDAppClient *)client didChangeState:(ARDAppClientState)state {
    switch (state) {
        case kARDAppClientStateConnected:
            NSLog(@"Client connected.");
            break;
        case kARDAppClientStateConnecting:
            NSLog(@"Client connecting.");
            break;
        case kARDAppClientStateDisconnected:
            NSLog(@"Client disconnected.");
            [self remoteDisconnected];
            break;
    }
}

- (void)appClient:(ARDAppClient *)client didReceiveLocalVideoTrack:(RTCVideoTrack *)localVideoTrack {
}

- (void)appClient:(ARDAppClient *)client didReceiveRemoteVideoTrack:(RTCVideoTrack *)remoteVideoTrack {

}

- (void)appClient:(ARDAppClient *)client didError:(NSError *)error {
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:nil
                                                        message:[NSString stringWithFormat:@"%@", error]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
    [self disconnect];
}

#pragma mark - RTCEAGLVideoViewDelegate

- (void)videoView:(RTCEAGLVideoView *)videoView didChangeVideoSize:(CGSize)size {

}


@end
