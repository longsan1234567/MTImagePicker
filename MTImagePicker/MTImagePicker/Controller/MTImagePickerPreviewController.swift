
//
//  ImageSelectorPreviewController.swift
//  CMBMobile
//
//  Created by Luo on 5/11/16.
//  Copyright © 2016 Yst－WHB. All rights reserved.
//
import UIKit
import AVFoundation

class MTImagePickerPreviewController:UIViewController,UICollectionViewDelegateFlowLayout,UICollectionViewDataSource {
    
    var dataSource:[MTImagePickerModel]!
    var selectedSource:Set<MTImagePickerModel>!
    var initialIndexPath:IndexPath?
    var maxCount:Int!
    var dismiss:((Set<MTImagePickerModel>) -> Void)?
    
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var collectionView: MTImagePickerCollectionView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var btnCheck: UIButton!
    @IBOutlet weak var lbSelected: UILabel!
    private var initialScrollDone = false
    
    class var instance:MTImagePickerPreviewController {
        get {
            let storyboard = UIStoryboard(name: "MTImagePicker", bundle: Bundle.main)
            let vc = storyboard.instantiateViewController(withIdentifier: "MTImagePickerPreviewController") as! MTImagePickerPreviewController
            return vc
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.lbSelected.text = String(self.selectedSource.count)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.scrollViewDidEndDecelerating(self.collectionView)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !self.initialScrollDone {
            self.initialScrollDone = true
            if let initialIndexPath = self.initialIndexPath {
                self.collectionView.scrollToItem(at: initialIndexPath, at: .right, animated: false)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let model = self.dataSource[indexPath.row]
        self.btnCheck.isSelected = self.selectedSource.contains(model)
        if model.mediaType == .Photo {
            let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath as IndexPath) as! ImagePickerPreviewCell
            cell.layer.shouldRasterize = true
            cell.layer.rasterizationScale = UIScreen.main.scale
            cell.initWithModel(model, controller: self)
            return cell
        } else {
            let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCell", for: indexPath as IndexPath) as! VideoPickerPreviewCell
            cell.layer.shouldRasterize = true
            cell.layer.rasterizationScale = UIScreen.main.scale
            cell.initWithModel(model: model,controller:self)
            return cell
        } 
    }
    
    // 旋转处理
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        if self.interfaceOrientation.isPortrait != toInterfaceOrientation.isPortrait {
            if let videoCell = self.collectionView.visibleCells.first as? VideoPickerPreviewCell {
                // CALayer 无法autolayout 需要重设frame
                videoCell.resetLayer(frame: UIScreen.main.compatibleBounds)
            }
            self.collectionView.prevItemSize = (self.collectionView.collectionViewLayout as! MTImagePickerPreviewFlowLayout).itemSize
            self.collectionView.prevOffset = self.collectionView.contentOffset.x
            self.collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.collectionView.bounds.width, height: self.collectionView.bounds.height)
    }
    
    //MARK:UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let videoCell = self.collectionView.visibleCells.first as? VideoPickerPreviewCell {
            videoCell.didScroll()
        }
    }
    
    //防止visibleCells出现两个而不是一个，导致.first得到的是未显示的cell
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.perform(#selector(MTImagePickerPreviewController.didEndDecelerating), with: nil, afterDelay: 0)
    }
    
    func didEndDecelerating() {
        let cell = self.collectionView.visibleCells.first
        if let videoCell = cell as? VideoPickerPreviewCell {
            videoCell.didEndScroll()
        } else if let imageCell = cell as? ImagePickerPreviewCell {
            imageCell.didEndScroll()
        }

    }
    
    @IBAction func btnBackTouch(_ sender: AnyObject) {
        self.dismiss?(self.selectedSource)
        let _ = self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnCheckTouch(_ sender: UIButton) {
        if self.selectedSource.count < self.maxCount || sender.isSelected == true {
            sender.isSelected = !sender.isSelected
            if let indexPath = self.collectionView.indexPathsForVisibleItems.first {
                let model = self.dataSource[indexPath.row]
                if sender.isSelected {
                    self.selectedSource.insert(model)
                    sender.heartbeatsAnimation(duration: 0.15)
                }else {
                    self.selectedSource.remove(model)
                }
                self.lbSelected.text = String(self.selectedSource.count)
                self.lbSelected.heartbeatsAnimation(duration: 0.15)
            }
        } else {
            let alertView = FlashAlertView(message: "Maxium selected".localized, delegate: nil)
            alertView.show()
        }
    }
}

