jQuery(function($) {

    'use strict';

    var _Blog = window._Blog || {};

    _Blog.toggleTheme = function() {
        $('.theme-switch').on('click', () => {
            $('body').toggleClass('dark-theme');
            window.isDark = !window.isDark;
            window.localStorage && window.localStorage.setItem('hodzue-memo-theme', window.isDark ? 'dark' : 'light');
            this.echarts();
        });
    };

    $(document).ready(() => {
        _Blog.toggleTheme();
    });
});
