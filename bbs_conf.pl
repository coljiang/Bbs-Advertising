use Modern::Perl;
{
    Log4perl => {
        'log4perl.rootLogger' => 'DEBUG, Logfile, Screen',
        'log4perl.appender.Logfile' => 'Log::Log4perl::Appender::File',
        'log4perl.appender.Logfile.filename' => $ENV{HOME}.'/cnv.log',
        'log4perl.appender.Logfile.layout'   => 'Log::Log4perl::Layout::PatternLayout',
        'log4perl.appender.Logfile.layout.ConversionPattern' => '[%P] %d - %p - %m%n',
        'log4perl.appender.Screen' => 'Log::Log4perl::Appender::ScreenColoredLevels',
        'log4perl.appender.Screen.stderr'  => 0,
        'log4perl.appender.Screen.color.TRACE' => 'cyan',
        'log4perl.appender.Screen.color.DEBUG' => 'cyan',
        'log4perl.appender.Screen.layout' => 'Log::Log4perl::Layout::SimpleLayout',
                }
}
