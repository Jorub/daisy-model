// log_clone.C
// 
// Copyright 1996-2001 Per Abrahamsen and S�ren Hansen
// Copyright 2000-2001 KVL.
//
// This file is part of Daisy.
// 
// Daisy is free software; you can redistribute it and/or modify
// it under the terms of the GNU Lesser Public License as published by
// the Free Software Foundation; either version 2.1 of the License, or
// (at your option) any later version.
// 
// Daisy is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser Public License for more details.
// 
// You should have received a copy of the GNU Lesser Public License
// along with Daisy; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

//
// Clone an object by using its log function.

#ifndef LOG_CLONE_H
#define LOG_CLONE_H

#include "log_alist.h"

class LogClone : public LogAList
{

  // Don't use this as a real log.
private:
  bool check_leaf (symbol) const;
  bool check_interior (symbol) const;
  bool match (const Daisy& daisy, Treelog&);
  void done (const std::vector<Time::component_t>& time_columns,
	     const Time&, double dt);
  bool initial_match (const Daisy&, Treelog&);
  void initial_done (const std::vector<Time::component_t>& time_columns,
		     const Time& time, double dt);

  // Get result.
public:
  const AttributeList& result ();

  // Create and Destroy.
public:
  void initialize (Treelog&);
  LogClone (const std::string& name, Block&);
  ~LogClone ();
};

#endif // LOG_CLONE_H
