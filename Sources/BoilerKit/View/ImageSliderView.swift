
import Foundation
import UIKit

import Kingfisher
import FlexLayout
import PinLayout
import CocoaChain
import CoCoaChain_FlexLayout


class ImageSliderView: UIView, UIScrollViewDelegate {
    
    struct ImageSliderItem {
        var imageSource: Kingfisher.Source?
        var placeholder: Kingfisher.Placeholder?
    }
    
    struct Configuration {
        var items: [ImageSliderItem]
        var autoScrollingInterval: TimeInterval?
        var backgroundColor = UIColor.clear
        var tapHandler: ((_ index: Int, _ item: ImageSliderItem) -> Void)?
        var isShowPageControl: Bool
        var bounces: Bool
        var currentPageIndicatorTintColor: UIColor? = nil
        var pageIndicatorTintColor: UIColor? = nil
    }
    
    
    private let flexView = UIView()
    
    private lazy var scrollView = UIScrollView()
        .chain
        .isPagingEnabled(true)
        .showsVerticalScrollIndicator(false)
        .showsHorizontalScrollIndicator(false)
        .delegate(self)
        .endChain
    
    private let scrollContentView = UIView()
    
    private lazy var pageControl = UIPageControl()
        .chain
        .addTarget(self, action: #selector(onPageValueChanged), for: .valueChanged)
        .endChain
    
    private var imageViews = [UIImageView]()
    
    private var configuration = Configuration(
        items: [],
        autoScrollingInterval: nil,
        backgroundColor: .clear,
        tapHandler: nil,
        isShowPageControl: false,
        bounces: false
    )
    
    private var autoSlideTimer: Timer? = nil
    
    var currentIndex: Int = 0
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.sharedInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func sharedInit() {
        self.flexView
            .chain
            .addSuperview(self)
            .flex { flex in
                flex.alignItems(.center)
                    .define { flex in
                        flex.addItem(self.scrollView)
                            .width(100%)
                            .height(100%)
                        
                        flex.addItem(self.pageControl)
                            .position(.absolute)
                            .bottom(5.0)
                            .maxWidth(100%)
                    }
            }
        
        self.scrollView
            .chain
            .flex { flex in
                flex.define { flex in
                    flex.addItem(self.scrollContentView)
                }
            }
    }
    
    func configure(_ configuration: Configuration) {
        self.configuration = configuration
        
        self.currentIndex = 0
        
        self.imageViews.forEach { $0.removeFromSuperview() }
        self.imageViews.removeAll(keepingCapacity: false)
        
        self.scrollView.bounces = configuration.bounces
        
        self.scrollContentView
            .flex
            .define { flex in
                flex.direction(.row)
                    .define { flex in
                        configuration.items.enumerated().forEach { index, item in
                            let imageView = UIImageView(frame: .init(origin: .zero, size: self.frame.size))
                                .chain
                                .contentMode(.scaleAspectFill)
                                .endChain
                            
                            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTapItem))
                            tapGesture.numberOfTapsRequired = 1
                            imageView.addGestureRecognizer(tapGesture)
                            
                            imageView.layer.setValue(index, forKey: "index")
                            
                            imageView.kf.indicatorType = .activity
                            imageView.kf.setImage(
                                with: item.imageSource,
                                placeholder: item.placeholder
                            ) { _ in
                            }
                            
                            self.imageViews.append(imageView)
                            
                            flex.addItem(imageView)
                                .define { flex in
                                    flex.width(self.frame.width)
                                        .height(100%)
                                }
                        }
                    }
            }
        
        self.pageControl.numberOfPages = configuration.items.count
        self.pageControl.currentPage = self.currentIndex
        self.pageControl.isHidden = !configuration.isShowPageControl
        if let color = configuration.currentPageIndicatorTintColor {
            self.pageControl.currentPageIndicatorTintColor = color
        }
        if let color = configuration.pageIndicatorTintColor {
            self.pageControl.pageIndicatorTintColor = color
        }
        
        self.resetSlideTimer()
        
        self.layout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layout()
    }
    
    private func layout() {
        self.flexView.pin.all()
        self.flexView.flex.layout()
        
        self.scrollContentView.pin.start().vertically()
        self.scrollContentView.flex.layout(mode: .adjustWidth)
        
        self.scrollView.contentSize = self.scrollContentView.frame.size
    }
    
    @objc private func onTapItem(_ sender: UITapGestureRecognizer) {
        guard let index = sender.view?.layer.value(forKey: "index") as? Int else { return }
        
        let item = self.configuration.items[index]
        
        self.configuration.tapHandler?(index, item)
    }
    
    private func resetSlideTimer() {
        self.autoSlideTimer?.invalidate()
        if self.configuration.items.count > 1,
           let timeInterval = self.configuration.autoScrollingInterval,
           timeInterval > 0 {
            self.autoSlideTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { _ in
                var newIndex = self.currentIndex + 1
                if newIndex >= self.configuration.items.count {
                    newIndex = 0
                    self.setCurrentIndex(newIndex, animated: false)
                } else {
                    self.setCurrentIndex(newIndex, animated: true)
                }
            }
        }
    }
    
    private func setCurrentIndex(_ value: Int, animated: Bool) {
        let newOffset: CGFloat = CGFloat(value) * self.scrollView.frame.width
        self.scrollView.setContentOffset(CGPoint(x: newOffset, y: 0), animated: animated)
        self.currentIndex = value
    }
    
    @objc private func onPageValueChanged(sender: UIPageControl) {
        self.resetSlideTimer()
        
        self.setCurrentIndex(sender.currentPage, animated: false)
    }
    
    // MARK: UIScrollViewDelegate
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.autoSlideTimer?.invalidate()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.resetSlideTimer()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let newIndex = Int(round(scrollView.contentOffset.x / scrollView.frame.size.width))
        self.pageControl.currentPage = newIndex
        self.currentIndex = newIndex
    }
}
