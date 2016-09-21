#ifndef ENGINE_LOGGING_HPP_
#define ENGINE_LOGGING_HPP_

#define BOOST_LOG_DYN_LINK

#include <boost/log/sources/severity_feature.hpp>
#include <boost/log/sources/severity_logger.hpp>
#include <boost/log/sources/record_ostream.hpp>
#include <boost/log/attributes/named_scope.hpp>
#include <boost/log/sources/global_logger_storage.hpp>

namespace src = boost::log::sources;

enum class LogSeverity {
  kTrace,
  kDebug,
  kInfo,
  kWarning,
  kError,
  kFatal,
};

BOOST_LOG_INLINE_GLOBAL_LOGGER_DEFAULT(global_logger, src::severity_logger_mt<LogSeverity>);

class ScopeLogger {
 public:
  ScopeLogger() : loginstance_(global_logger::get()) {
    BOOST_LOG_SEV(loginstance_, LogSeverity::kTrace) << "Begin";
  }

  ~ScopeLogger() {
    BOOST_LOG_SEV(loginstance_, LogSeverity::kTrace) << "End";
  }

 private:
  src::severity_logger_mt<LogSeverity>& loginstance_;
};

#define GET_NAMED_SCOPE_FUNCTION_GLOBAL_LOGGER(logger_name, name)\
  boost::log::attributes::named_scope::sentry BOOST_LOG_UNIQUE_IDENTIFIER_NAME(scope_sentry1_)(name, __FILE__, __LINE__);\
  boost::log::attributes::named_scope::sentry BOOST_LOG_UNIQUE_IDENTIFIER_NAME(scope_sentry2_)(BOOST_CURRENT_FUNCTION, __FILE__, __LINE__, boost::log::attributes::named_scope_entry::function);\
  ScopeLogger scope_logger_instance;\
  auto& logger_name = global_logger::get()

void InitializeLogging();

#endif  // ENGINE_LOGGING_HPP_
