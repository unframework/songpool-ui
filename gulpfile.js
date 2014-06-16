var gulp = require('gulp');

var serve = require('gulp-serve');
var less = require('gulp-less');
var concat = require('gulp-concat');
var rimraf = require('rimraf');

var stylesSrc = 'src/**/*.less';

gulp.task('clean', function(cb) {
    rimraf('build', cb);
});

gulp.task('styles', ['clean'], function() {
    return gulp.src(stylesSrc)
        .pipe(less())
        .pipe(concat('styles.css'))
        .pipe(gulp.dest('build'));
});

gulp.task('serve', serve({
    root: [__dirname]
}));

gulp.task('watch', function() {
    gulp.watch(stylesSrc, ['styles']);
});

gulp.task('default', ['clean', 'styles', 'watch', 'serve']);