//
//  TJPickerViewModel.m
//  TJActionSheet
//
//  Created by 王朋涛 on 17/2/20.
//  Copyright © 2017年 tao. All rights reserved.
//

#import "TJPickerViewModel.h"
#import "TJImagePickerManager.h"
#import <MediaPlayer/MediaPlayer.h>
#import <MediaPlayer/MPMoviePlayerController.h>
#import <MediaPlayer/MPMoviePlayerViewController.h>

@interface TJPickerViewModel ()
@property (nonatomic,strong) MWPhotoBrowser *webphotoBrowser;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic,assign) TJAssetReportMediaType  type;


@end


@implementation TJPickerViewModel
#pragma mark - 单利
+ (instancetype)shareSingle
{
    static TJPickerViewModel * _manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _manager = [[self alloc]init];
        _manager.videoMaximumDuration = 30.0f;
        _manager.maximumNumberOfSelection = 3;
    });
    return _manager;
}
#pragma mark - 懒加载

-(MWPhotoBrowser *)webphotoBrowser{
    if (!_webphotoBrowser) {
        _webphotoBrowser= [[MWPhotoBrowser alloc] initWithDelegate:(id)self];
        _webphotoBrowser.displayNavArrows = YES;
        _webphotoBrowser.enableSwipeToDismiss = YES;
    }
    return _webphotoBrowser;
    
}
#pragma mark - MWPhotoBrowserDelegate
- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return _photos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < _photos.count)
        return [_photos objectAtIndex:index];
    return nil;
}
#pragma mark - 播放图片或者视频
- (void)playMediaViewWithAsset:(id)asset image:(UIImage *)image{
    
    //播放图片或视频
    if (image) {//图片
        [[TJImagePickerManager shareInstance]getOriginalPhotoWithAsset:asset completion:^(UIImage *photo, NSDictionary *info) {
            NSMutableArray *photos = [[NSMutableArray alloc] init];
            [photos addObject:[MWPhoto photoWithImage:photo]];
            self.photos=photos;
            [self.webphotoBrowser setCurrentPhotoIndex:0];
            [self.webphotoBrowser reloadData];
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:self.webphotoBrowser];
            nc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            [[[ UIApplication sharedApplication ] keyWindow ].rootViewController presentViewController:nc animated:YES completion:nil];
        }];
    }else{//视频
        
        [[TJImagePickerManager shareInstance]getVideoOutputPathWithAsset:asset completion:^(NSString *outputPath) {
            //            UIImage *photo = [TJImagePickerManager getVideoImageFromPathUrl:[NSURL fileURLWithPath:outputPath]];
            NSMutableArray *photos = [[NSMutableArray alloc] init];
            //            [photos addObject:[MWPhoto photoWithImage:photo]];
            [photos addObject:[MWPhoto videoWithURL:[NSURL fileURLWithPath:outputPath]]];
            self.photos=photos;
            [self.webphotoBrowser setCurrentPhotoIndex:0];
            [self.webphotoBrowser reloadData];
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:self.webphotoBrowser];
            nc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            [[[ UIApplication sharedApplication ] keyWindow ].rootViewController presentViewController:nc animated:YES completion:nil];
            
        }];
        
        
    }


}

#pragma mark - 附件上报
- (void)takeAssetWithStyle:(TJAssetReportMediaType)type{
    self.type = type;
    if (type ==TJAssetReportMediaTypePhoto) {//选择照片
        QBImagePickerController* _multipleImagePickerController = [QBImagePickerController new];
        _multipleImagePickerController.delegate = self;
        _multipleImagePickerController.mediaType = QBImagePickerMediaTypeImage;
        _multipleImagePickerController.allowsMultipleSelection = YES;
        _multipleImagePickerController.showsNumberOfSelectedAssets = YES;
        _multipleImagePickerController.maximumNumberOfSelection = self.maximumNumberOfSelection;
        [[[ UIApplication sharedApplication ] keyWindow ].rootViewController presentViewController:_multipleImagePickerController animated:YES completion:NULL];
        
    }else if (type==TJAssetReportMediaTypeCamera){//拍照
        if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
            UIImagePickerController *imagePickerController = [UIImagePickerController new];
            //            [imagePickerController setAllowsEditing:YES];// 设置是否可以管理已经存在的图片或者视频
            imagePickerController.delegate = self;
            imagePickerController.title=@"照片";
            if ([[TJImagePickerManager shareInstance] isCameraAvailable]) {
                imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
                [[[ UIApplication sharedApplication ] keyWindow ].rootViewController presentViewController:imagePickerController animated:YES completion:NULL];
            }
        }
        
    }else if (type==TJAssetReportMediaTypeCameraShot){//拍摄
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            UIImagePickerController *imagePickerController = [UIImagePickerController new];
            imagePickerController.delegate = self;
            imagePickerController.title=@"拍摄";
            imagePickerController.mediaTypes = [NSArray arrayWithObject:@"public.movie"];
            imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
            imagePickerController.videoMaximumDuration = self.videoMaximumDuration;//设置最长录制5分钟
            [[[ UIApplication sharedApplication ] keyWindow ].rootViewController presentViewController:imagePickerController animated:YES completion:NULL];
        }
    
    }
    else if(type == TJAssetReportMediaTypeVideo) {//选择视频并编辑
        QBImagePickerController* _multipleImagePickerController = [QBImagePickerController new];
        _multipleImagePickerController.delegate = self;
        _multipleImagePickerController.mediaType = QBImagePickerMediaTypeVideo;
        _multipleImagePickerController.allowsMultipleSelection = YES;
        _multipleImagePickerController.showsNumberOfSelectedAssets = YES;
        _multipleImagePickerController.maximumNumberOfSelection = 1;
        [[[ UIApplication sharedApplication ] keyWindow ].rootViewController presentViewController:_multipleImagePickerController animated:YES completion:NULL];
        
    }
    else if(type == TJAssetReportMediaTypeAudio) {//音频
        UIView * view = [[ UIApplication sharedApplication ] keyWindow ];
        TJAudioPlayerView *playerView =[[TJAudioPlayerView alloc]initWithFrame:view.frame];
        playerView.delegate = self;
        [view addSubview:playerView];
    }
    
    
}

#pragma mark - QBImagePickerControllerDelegate
//选择图片或者视频
- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didFinishPickingAssets:(NSArray *)assets
{
    [[[ UIApplication sharedApplication ] keyWindow ].rootViewController dismissViewControllerAnimated:YES completion:NULL];
    if (imagePickerController.mediaType == QBImagePickerMediaTypeVideo) {//TJAssetReportMediaTypeVideo
        PHAsset *asset = assets.firstObject;
        [[TJImagePickerManager shareInstance]getVideoOutputPathWithAsset:asset completion:^(NSString *outputPath) {
            CGFloat videoTime = [TJImagePickerManager getVideoTotaltime:[NSURL fileURLWithPath:outputPath]];
            if (videoTime>self.maximumNumberOfSelection) {
                UIVideoEditorController *editVC;
                // 检查这个视频资源能不能被修改
                if ([UIVideoEditorController canEditVideoAtPath:outputPath]) {
                    editVC = [[UIVideoEditorController alloc] init];
                    editVC.videoMaximumDuration = self.maximumNumberOfSelection;
                    editVC.videoPath = outputPath;
                    editVC.delegate = self;
                    [[[ UIApplication sharedApplication ] keyWindow ].rootViewController  presentViewController:editVC animated:YES completion:nil];
                }

            }else{
            //小于最大限制
                if (self.delegate &&[self.delegate respondsToSelector:@selector(tj_imagePickerViewModelStyle:didFinishPickingAssets:)]) {
                    [self.delegate tj_imagePickerViewModelStyle:self.type didFinishPickingAssets:@[outputPath]];
                }
            }
        }];
        
        
        
    }else{//TJAssetReportMediaTypePhoto
        if (self.delegate &&[self.delegate respondsToSelector:@selector(tj_imagePickerViewModelStyle:didFinishPickingAssets:)]) {
            [self.delegate tj_imagePickerViewModelStyle:self.type didFinishPickingAssets:assets];
        }
    }
    

}
- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController
{
    NSLog(@"Canceled.");
    [[[ UIApplication sharedApplication ] keyWindow ].rootViewController dismissViewControllerAnimated:YES completion:NULL];
}
#pragma mark - VideoEditorControllerDelegate
//视频编辑
- (void)videoEditorController:(UIVideoEditorController *)editor didSaveEditedVideoToPath:(NSString *)editedVideoPath{

    if (self.delegate &&[self.delegate respondsToSelector:@selector(tj_imagePickerViewModelStyle:didFinishPickingAssets:)]) {
        [[[ UIApplication sharedApplication ] keyWindow ].rootViewController dismissViewControllerAnimated:YES completion:NULL];

        [self.delegate tj_imagePickerViewModelStyle:self.type didFinishPickingAssets:@[editedVideoPath]];
    }
}

#pragma mark - imagePickerControllerDelegate
//拍摄或者拍照
- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    NSString *type = [info objectForKey:UIImagePickerControllerMediaType];
    if ([type isEqualToString:@"public.image"]) {
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        [[TJImagePickerManager shareInstance] saveAssectWithAlbumName:@"应急指挥" fileUrl:nil fileImage:image completion:^(NSError *error) {
            if (error) {
                NSLog(@"图片保存失败 %@",error);
            }else{
                ///成功保存后进行获取
                [[TJImagePickerManager shareInstance] getAssetsWithAllowPickingVideo:NO allowPickingImage:YES completion:^(NSArray<TJAssetModel *> *models) {
                    TJAssetModel *assetModel = [models lastObject];
                    if (self.delegate &&[self.delegate respondsToSelector:@selector(tj_imagePickerViewModelStyle:didFinishPickingAssets:)]) {
                        [self.delegate tj_imagePickerViewModelStyle:self.type didFinishPickingAssets:@[assetModel.asset]];
                    }
                    
                    
                    
                }];
            }
        }];
        
    }else{
        NSURL *videoURL = [info objectForKey:UIImagePickerControllerMediaURL];
        [[TJImagePickerManager shareInstance] saveAssectWithAlbumName:@"应急指挥" fileUrl:videoURL fileImage:nil completion:^(NSError *error) {
            if (error) {
                NSLog(@"视频保存失败 %@",error);
            }else{
                ///成功保存后进行获取
                [[TJImagePickerManager shareInstance] getAssetsWithAllowPickingVideo:YES allowPickingImage:NO completion:^(NSArray<TJAssetModel *> *models) {
                    TJAssetModel *assetModel = [models lastObject];
                    [[TJImagePickerManager shareInstance]getVideoOutputPathWithAsset:assetModel.asset completion:^(NSString *outputPath) {
                        if (self.delegate &&[self.delegate respondsToSelector:@selector(tj_imagePickerViewModelStyle:didFinishPickingAssets:)]) {
                            [self.delegate tj_imagePickerViewModelStyle:self.type didFinishPickingAssets:@[outputPath]];
                        }
                    }];
                    
                   

                    
                    
                }];
            }
        }];
        
    }
}

#pragma mark - TJAudioPlayerViewDelegate
//音频回调
- (void)audioPlayerDidFinishPlaying:(TJAudioPlayerView *)playerView path:(NSString *)path{
    if (self.delegate &&[self.delegate respondsToSelector:@selector(tj_imagePickerViewModelStyle:didFinishPickingAssets:)]) {
        [self.delegate tj_imagePickerViewModelStyle:self.type didFinishPickingAssets:@[path]];
    }
}




@end
