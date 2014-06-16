var gulp = require('gulp');

var serve = require('gulp-serve');
var less = require('gulp-less');
var concat = require('gulp-concat');
var livereload = require('gulp-livereload');
var plumber = require('gulp-plumber');
var rimraf = require('rimraf');

var stylesSrc = 'src/**/*.less';

gulp.task('clean', function(cb) {
    rimraf('build', cb);
});

gulp.task('styles', ['clean'], function() {
    return gulp.src(stylesSrc)
        .pipe(plumber())
        .pipe(less())
        .pipe(concat('styles.css'))
        .pipe(gulp.dest('build'))
        .pipe(livereload());
});

gulp.task('serve', serve({
    root: [__dirname]
}));

gulp.task('watch', function() {
    gulp.watch(stylesSrc, ['styles']);
});

gulp.task('default', ['clean', 'styles', 'watch', 'serve']);