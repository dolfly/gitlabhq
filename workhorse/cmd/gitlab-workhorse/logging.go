package main

import (
	"fmt"
	"io"
	goLog "log"
	"log/slog"
	"os"

	log "github.com/sirupsen/logrus"
	logkit "gitlab.com/gitlab-org/labkit/log"
	logv2 "gitlab.com/gitlab-org/labkit/v2/log"
)

const (
	jsonLogFormat    = "json"
	textLogFormat    = "text"
	structuredFormat = "structured"
	noneLogType      = "none"
)

// Configure global Labkit v2 slog instance.
func configureLoggingV2(file string, format string) (*slog.Logger, io.Closer, error) {
	var cfg logv2.Config

	switch format {
	case jsonLogFormat:
		cfg.UseTextFormat = false
	case textLogFormat:
		cfg.UseTextFormat = true
	case noneLogType:
		cfg.Writer = io.Discard
	case structuredFormat:
		// TODO: Remove and error on unrecognized format after migration to log v2 is complete
		fmt.Fprintf(os.Stderr,
			"'%s' format is deprecated for labkit/v2/log, falling back to json\n",
			format)
		cfg.UseTextFormat = false
	default:
		return nil, nil, fmt.Errorf("unrecognized format value %q, please use json or text", format)
	}

	var (
		logger *slog.Logger
		closer io.Closer
	)

	if file == "" || file == "stderr" {
		logger = logv2.NewWithConfig(&cfg)
		closer = io.NopCloser(nil)
	} else {
		var err error
		logger, closer, err = logv2.NewWithFile(file, &cfg)
		if err != nil {
			return nil, nil, err
		}
	}

	return logger, closer, nil
}

// Configure global labkit v1 logrus logger
// NOTE: To be removed after all log call sites are modified to use labkit v2 logger
func configureLoggingV1(file string, format string) (io.Closer, error) {
	// Golog always goes to stderr
	goLog.SetOutput(os.Stderr)

	if file == "" {
		file = "stderr"
	}

	switch format {
	case noneLogType:
		return logkit.Initialize(logkit.WithWriter(io.Discard))
	case jsonLogFormat:
		return logkit.Initialize(
			logkit.WithOutputName(file),
			logkit.WithFormatter("json"),
		)
	case textLogFormat:
		// In this mode, default (non-access) logs will always go to stderr
		return logkit.Initialize(
			logkit.WithOutputName("stderr"),
			logkit.WithFormatter("text"),
		)
	case structuredFormat:
		return logkit.Initialize(
			logkit.WithOutputName(file),
			logkit.WithFormatter("color"),
		)
	}

	return nil, fmt.Errorf("unknown logFormat: %v", format)
}

// In text format, we use a separate logger for access logs
func getAccessLogger(file string, format string) (*log.Logger, io.Closer, error) {
	if format != "text" {
		return log.StandardLogger(), io.NopCloser(nil), nil
	}

	if file == "" {
		file = "stderr"
	}

	accessLogger := log.New()
	accessLogger.SetLevel(log.InfoLevel)
	closer, err := logkit.Initialize(
		logkit.WithLogger(accessLogger),  // Configure `accessLogger`
		logkit.WithFormatter("combined"), // Use the combined formatter
		logkit.WithOutputName(file),
	)

	return accessLogger, closer, err
}
