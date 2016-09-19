#include "./logging.hpp"

#include <fstream>
#include <iomanip>
#include <boost/core/null_deleter.hpp>
#include <boost/date_time/posix_time/posix_time.hpp>
#include <boost/log/expressions.hpp>
#include <boost/log/utility/setup/common_attributes.hpp>
#include <boost/log/sinks/sync_frontend.hpp>
#include <boost/log/sinks/text_ostream_backend.hpp>
#include <boost/smart_ptr/make_shared_object.hpp>

namespace logging = boost::log;
namespace expr = boost::log::expressions;
namespace sinks = boost::log::sinks;
namespace attrs = boost::log::attributes;

std::ostream& operator<<(std::ostream& strm, LogSeverity level) {
  static const char* strings[] = {
    "Trace",
    "Debug",
    "Info",
    "Warning",
    "Error",
    "Fatal",
  };

  auto level_index = static_cast<std::size_t>(level);

  if (level_index < sizeof(strings) / sizeof(*strings)) {
    strm << strings[level_index];
  } else {
    strm << level_index;
  }

  return strm;
}

BOOST_LOG_ATTRIBUTE_KEYWORD(time_stamp, "TimeStamp", boost::posix_time::ptime)
BOOST_LOG_ATTRIBUTE_KEYWORD(line_id, "LineID", unsigned int)
BOOST_LOG_ATTRIBUTE_KEYWORD(severity, "Severity", LogSeverity)
BOOST_LOG_ATTRIBUTE_KEYWORD(scope, "Scope", attrs::named_scope::value_type)
BOOST_LOG_ATTRIBUTE_KEYWORD(tag_attr, "Tag", std::string)

void InitializeLogging() {
  logging::add_common_attributes();
  logging::core::get()->add_global_attribute("Scope", attrs::named_scope());

  // TODO: Should this go in an init function instead?
  logging::formatter console_format = expr::stream
    << std::setw(8) << std::setfill('0') << line_id << std::setfill(' ')
    << " <" << severity << ">"
    << ": <" << scope << ">\t"
    << expr::if_(expr::has_attr(tag_attr))
      [
        expr::stream << "[" << tag_attr << "] "
      ]
    << expr::smessage;

  typedef sinks::synchronous_sink<sinks::text_ostream_backend> text_sink;

  boost::shared_ptr<text_sink> sink = boost::make_shared<text_sink>();
  boost::shared_ptr<std::ostream> console_stream(&std::cout, boost::null_deleter());
  sink->locked_backend()->add_stream(console_stream);
  sink->set_filter(severity == LogSeverity::kInfo);  // TODO: Add debug if configured to do so (compile time?), tracing also as a flag
  sink->set_formatter(console_format);
  logging::core::get()->add_sink(sink);

  sink = boost::make_shared<text_sink>();
  boost::shared_ptr<std::ostream> console_error_stream(&std::cerr, boost::null_deleter());
  sink->locked_backend()->add_stream(console_error_stream);
  sink->set_filter(severity >= LogSeverity::kWarning);
  sink->set_formatter(console_format);
  logging::core::get()->add_sink(sink);

  sink = boost::make_shared<text_sink>();
  sink->locked_backend()->add_stream(
    boost::make_shared<std::ofstream>("full.log"));  // TODO: Put in application's writable directory
  sink->set_filter(severity >= LogSeverity::kInfo);  // TODO: Add debug if configured to do so (compile time?), tracing also as a flag
  sink->set_formatter(
    expr::stream
      << "[" << time_stamp << "]"
      << " " << std::setw(8) << std::setfill('0') << line_id << std::setfill(' ')
      << " <" << severity << ">"
      << ": <" << scope << ">\t"
      << expr::if_(expr::has_attr(tag_attr))
        [
          expr::stream << "[" << tag_attr << "] "
        ]
      << expr::smessage);
  logging::core::get()->add_sink(sink);
}
