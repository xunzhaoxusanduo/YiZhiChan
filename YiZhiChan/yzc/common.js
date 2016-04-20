window.console = window.console || { info: function () { } };


var translate = function ($ele, top, left, speed) {

    var slide = $ele[0];

    var style = slide && slide.style;

    if (!style) return;

    if (speed) {
        style.webkitTransitionDuration =
        style.MozTransitionDuration =
        style.msTransitionDuration =
        style.OTransitionDuration =
        style.transitionDuration = speed + 'ms';
    }

    if ($.browser.msie || true) {

        style.webkitTransform = 'translate3d(' + left + 'px,' + top + 'px,0)' + 'translateZ(0)';
        style.transform = 'translate3d(' + left + 'px,' + top + 'px,0)' + 'translateZ(0)';
        style.msTransform =
        style.MozTransform =
        style.OTransform = 'translateX(' + left + 'px) translateY(' + top + 'px)';


    } else {
        $ele.css({ transform: 'translate3d(' + left + 'px,' + top + 'px,0)' });

    }
}

var lansum = {
    init: function () {
         
        lansum.slide.init();
        
    }

}

lansum.slide = {
    init: function () {
    

        var s4 = new lansum.slide.s1();
        s4.selContainer = '.imgSlideContainer';
        s4.isBlur = true;
        s4.itemWidth = 540;
        s4.selItem = '.pressscroll';
        s4.fullScreen = true;
        s4.maxCount = 1;
        s4.init();

 




    }
}//end lansum.slide

lansum.slide.s1 = function () {
    this.selContainer = '.imgSlideContainer';
    this.selBlock = '.imgSlideBlock';
    this.selLeft = '.arrowscrollleft-s';
    this.selRight = '.arrowscrollright-s';
    this.selItem = 'li';
    this.currentIndex = 1;
    this.maxCount = 3;
    this.itemWidth = 300;
    this.fullScreen = false;
    this.marginLeft = 0;
    this.animateTime = 1000;
    this.isBindSwipe = true;
    this.isBlur = false;
    this.init = function (isBindEvent) {


        this.$selContainer = $(this.selContainer);
        this.$selBlock = $(this.selContainer + ' ' + this.selBlock);
        this.$selLeft = $(this.selContainer + ' ' + this.selLeft);
        this.$selRight = $(this.selContainer + ' ' + this.selRight);
        this.$selItem = this.$selBlock.find(this.selItem)
        //this.itemWidth = this.$selItem.first().width();
        if (this.fullScreen) {
            this.marginLeft = ($(window).width() - this.itemWidth) / 2;
            this.$selItem.css({ marginRight: this.marginLeft });
        }
        if (this.maxCount == 1) {
            this.$selBlock.width(this.itemWidth);

        }
        this.$selBlock.children().first().width(this.$selItem.length * (this.itemWidth + this.marginLeft));
        if (isBindEvent == undefined) {

            this.$selLeft.bind('click', this, this.funLeft);
            this.$selRight.bind('click', this, this.funRight);


        }

        if (this.isBlur)
        {
            var $imgs = this.$selItem.find('img');
            for (var i = $imgs.length - 1; i >= 0; i--) {
                var $img = $imgs.eq(i);
                this.$selContainer.prepend('<img class="bg img2" src="' + $img.attr('src') + '" />')
            }
           
        }

        if (this.isBindSwipe) {
            this.$selBlock

            .data('mine', this)
            .swipe({
                swipeStatus: this.swipeStatus,
                allowPageScroll: 'vertical'
            });
        }

        var maxIndex = this.$selItem.length - this.maxCount + 1;

        this.$selRight.css({ opacity: 1 });
        this.$selLeft.css({ opacity: 1 });

        if (this.currentIndex >= maxIndex) {
            this.$selRight.css({ opacity: 0.3 });
        }
        if (this.currentIndex <= 1) {
            this.$selLeft.css({ opacity: 0.3 });
        }

        console.info(this.selContainer + ' slide ' + this.currentIndex);

        this.funMove(this, false);

    };

    this.funLeft = function (e) {
        console.info('move:left')
        var obj = e.data;
        console.info('' + e.data.selContainer);

        if (obj.isRunning) {
            return;
        } else {
            obj.isRunning = true;
        }
        if (obj.currentIndex > 1) {
            var $current = obj.$selItem.eq(obj.currentIndex - 1);
            if ($current) {
                //Left-side text scrolling scope, the bigger the number the more distance the text and image will have
                var d = 280;
                var $rrr = $current.find(".floattext");
                $rrr.each(function (i, ele) {
                    var $item = $(ele);
                    var left = parseInt($item.css('left').replace(/px/, ''));
                    $item.delay(2).animate({ left: left + d }, 800, 'easeOutCirc')
                    .animate({ left: left }, 800);

                });

            }
        }


        obj.currentIndex--;
        obj.$selRight.css({ opacity: 1 });


        if (obj.currentIndex <= 1) {
            obj.$selLeft.css({ opacity: 0.3 });
        } else {
            obj.$selLeft.css({ opacity: 1 });

        }



        obj.funMove(e.data);
    };

    this.funRight = function (e) {
        console.info('move:right')

        var obj = e.data;
        console.info('' + e.data.selContainer + ' ' + e.data.currentIndex);
        if (obj.isRunning) {
            return;
        } else {
            obj.isRunning = true;
        }
        var maxIndex = obj.$selItem.length - obj.maxCount + 1;

        if (obj.currentIndex < maxIndex) {
            //            console.info('obj.currentIndex:' + obj.currentIndex)
            var $current = obj.$selItem.eq(obj.currentIndex - 1);
            if ($current) {
                //Right-side text scrolling scope, the bigger the number the more distance the text and image will have
                var d = 280;
                var $rrr = $current.find(".floattext");
                $rrr.each(function (i, ele) {
                    var $item = $(ele);
                    var left = parseInt($item.css('left').replace(/px/, ''));
                    $item.delay(2).animate({ left: left - d }, 800, 'easeOutCirc')
                    .animate({ left: left }, 800);

                });

            }
        }


        obj.currentIndex++;
        obj.$selLeft.css({ opacity: 1 });

        if (obj.currentIndex >= maxIndex) {
            obj.$selRight.css({ opacity: 0.3 });
        } else {
            obj.$selRight.css({ opacity: 1 });

        }
        obj.funMove(e.data);
    };
    this.funMove = function (obj, isAnimate) {
        var maxIndex = obj.$selItem.length - obj.maxCount + 1;
        if (obj.currentIndex == maxIndex) {

        }

        if (obj.currentIndex > maxIndex) {
            obj.currentIndex = maxIndex;
        }



        if (obj.currentIndex < 1) {
            obj.currentIndex = 1;
        }
        if (obj.isBlur)
        {
            var bgList = obj.$selContainer.find('.bg');
            var bgCurrent = bgList.eq(obj.currentIndex - 1);
            //bgList.addClass('img2').removeClass('img1');
            //bgCurrent.addClass('img1').removeClass('img2');

            bgList.hide();
            bgCurrent.show();
            //bgCurrent.fadeIn(1000);
            

        }


        var left = (obj.itemWidth + obj.marginLeft) * (obj.currentIndex - 1);
        //if (isAnimate == false) {

        //    obj.$selBlock.children().first().css({ marginLeft: -left });
        //} else {
        if ($.browser.msie) {
            obj.$selBlock.children().first().animate({ marginLeft: -left }, obj.animateTime, 'easeOutCirc', function () {
                obj.isRunning = false;
            });
        } else {
            setTimeout(function () {
                obj.isRunning = false;
            }, obj.animateTime)

            translate(obj.$selBlock.children().first(), 0, -left, obj.animateTime)
        }

        //}


    };

    this.swipeStatus = function (event, phase, direction, distance, duration, fingers) {
        var $this = $(this);
        var data = $this.data('mine');
        console.info('swipeStatus');
        if (phase == "end" || phase == "cancel") {

            if (distance < data.minDistance) {

            } else {
                if (direction == "left") {
                    data.$selRight.click();
                }
                if (direction == 'right') {
                    data.$selLeft.click();
                }
            }


        }


    }
}//end lansum.slide.s1




$(function () {
    lansum.init(); //init
 
})
