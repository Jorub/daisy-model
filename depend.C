// depend.C -- Find dependencies in datastructures.
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

#define BUILD_DLL

#include "depend.h"
#include "traverse.h"
#include "library.h"
#include "metalib.h"
#include "frame_model.h"
#include "treelog.h"
#include "assertion.h"
#include <algorithm>
#include <numeric>
#include <sstream>

class TraverseDepend : public Traverse
{
private:
  // We store it here.
  Treelog& treelog;
  dep_map& dependencies;

  // What depend on this parameterization?
  const symbol dep_lib;
  const symbol dep_par;
  
  // Find _all_ depencied?
  const bool find_all;

  // The parameterization we currently test.
  bool found;
public:
  bool found_any;

  // Create & Destroy.
public:
  TraverseDepend (Metalib&, symbol component, symbol parameterization, 
		  Treelog& treelog, dep_map& dependencies, bool find_all);
  ~TraverseDepend ();

private:
  // Implementation.
  bool enter_library (Library& library, symbol component);
  void leave_library ();
  bool enter_model (Frame& frame,
		    symbol component, symbol model);
  void leave_model (symbol component, symbol name);
  bool enter_submodel (Frame& frame, const Frame& default_alist, 
  		       const symbol name, const symbol registered);
  void leave_submodel ();
  bool enter_submodel_default (const Frame& default_frame,
			       const symbol name, const symbol registered);
  void leave_submodel_default ();
  bool enter_submodel_sequence (const Frame& frame, 
                                const Frame& default_frame,
  				const symbol name, unsigned index, 
                                const symbol registered);
  void leave_submodel_sequence ();
  bool enter_submodel_sequence_default (const Frame& default_frame,
  					const symbol name, const symbol registered);
  void leave_submodel_sequence_default ();
  bool enter_object (const Library&, 
		     const Frame& frame, const Frame& default_frame,
  		     const symbol name);
  void leave_object ();
  bool enter_object_sequence (const Library&, 
                              const Frame& frame, const Frame& default_frame,
  			      const symbol name, 
  			      unsigned index);
  void leave_object_sequence ();
  bool enter_parameter (const Frame& frame, const Frame& default_frame,
			const symbol name, const symbol parameter);
  void leave_parameter ();
};

bool
TraverseDepend::enter_library (Library&, const symbol component)
{
  if (found_any && !find_all)
    return false;
  treelog.open (component);
  return true;
}

void
TraverseDepend::leave_library ()
{ treelog.close (); }

bool
TraverseDepend::enter_model (Frame& frame,
			     const symbol component, const symbol name)
{
  // Check if this model is inherited from the model we are examining.
  if (dep_lib == component
      && frame.type_name () == dep_par)
    { 
      Treelog::Open nest1 (treelog, name);
      treelog.entry (dep_par + " inherited by " + name);
      found_any = true;

      if (find_all)
	{
	  // Find stuff dependend on this model.
	  Treelog::Open nest2 (treelog, "Recursive dependencies");
	  dependencies[component].insert (name);
	  TraverseDepend recurse (metalib, component, name, 
				  treelog, dependencies, find_all);
	  recurse.traverse_all_libraries ();
	}

      // We don't examine the content of this model then.
      return false;
    } 
  treelog.open (name);
  return true;
}

void
TraverseDepend::leave_model (const symbol component, const symbol name)
{ 
  if (found && find_all)
    {
      // Found, search for stuff dependend on this model.
      Treelog::Open nest (treelog, "Recursive dependencies");
      dependencies[component].insert (name);
      TraverseDepend recurse (metalib, component, name,
			      treelog, dependencies, find_all);
      recurse.traverse_all_libraries ();

      // Clear flag for next model.
      found = false;
    }
  treelog.close (); 
}

bool
TraverseDepend::enter_submodel (Frame&, const Frame&,
				const symbol name, const symbol registered)
{
  treelog.open (name);
  return true; 
}

void
TraverseDepend::leave_submodel ()
{ treelog.close (); }

bool
TraverseDepend::enter_submodel_default (const Frame&, 
                                        const symbol, const symbol)
{ return false; }

void
TraverseDepend::leave_submodel_default ()
{ daisy_notreached (); }

bool
TraverseDepend::enter_submodel_sequence (const Frame&, const Frame&,
					 const symbol name, unsigned index, 
                                         const symbol)
{ 
  std::ostringstream str;
  str << name << "[" << index << "]";
  treelog.open (str.str ());
  return true; 
}

void
TraverseDepend::leave_submodel_sequence ()
{ treelog.close (); }

bool
TraverseDepend::enter_submodel_sequence_default (const Frame&,
						 const symbol, const symbol)
{ return false; }

void
TraverseDepend::leave_submodel_sequence_default ()
{ daisy_notreached (); }

bool
TraverseDepend::enter_object (const Library& library, 
			      const Frame& frame, const Frame&,
			      const symbol name)
{
  const symbol super = frame.type_name ();
  daisy_assert (super != Value::None ());
  if (dep_lib == library.name () && super == dep_par)
    { 
      treelog.entry (name + " inherits " + dep_par);
      found_any = true;
      found = true;
      return false;
    }
  treelog.open (name + " (" + super + ")");
  return true; 
}

void
TraverseDepend::leave_object ()
{ treelog.close (); }

bool
TraverseDepend::enter_object_sequence (const Library& library, 
				       const Frame& frame,
                                       const Frame& default_frame,
				       const symbol name, unsigned index)
{ 
  std::ostringstream str;
  str << name << "[" << index << "]";

  return enter_object (library, frame, default_frame, str.str ());
}

void
TraverseDepend::leave_object_sequence ()
{ leave_object (); }

bool
TraverseDepend::enter_parameter (const Frame&, const Frame&,
				 const symbol, const symbol)
{ return true; }

void 
TraverseDepend::leave_parameter ()
{ }

TraverseDepend::TraverseDepend (Metalib& mlib,
                                const symbol component,
				const symbol parameterization,
				Treelog& tlog,
				dep_map& deps, bool fa)
  : Traverse (mlib),
    treelog (tlog),
    dependencies (deps),
    dep_lib (component),
    dep_par (parameterization),
    find_all (fa),
    found (false),
    found_any (false)
{ }

TraverseDepend::~TraverseDepend ()
{ }

bool
has_dependencies (Metalib& metalib,
                  const symbol component, const symbol parameterization)
{
  dep_map dependencies;
  TraverseDepend depend (metalib, component, parameterization,
			 Treelog::null (), dependencies, false);
  depend.traverse_all_libraries ();

  return depend.found_any;
}

bool
check_dependencies (Metalib& metalib,
                    const symbol component, const symbol parameterization, 
		    Treelog& treelog)
{
  dep_map dependencies;
  TraverseDepend depend (metalib, component, parameterization, 
			 treelog, dependencies, true);
  depend.traverse_all_libraries ();

  return depend.found_any;
}

bool
find_dependencies (Metalib& metalib,
                   const symbol component, const symbol parameterization, 
		   dep_map& dependencies)
{
  TraverseDepend depend (metalib, component, parameterization, 
			 Treelog::null (), dependencies, true);
  depend.traverse_all_libraries ();

  return depend.found_any;
}

static int
sequence_number (Metalib& metalib,
                 const symbol component, const symbol parameterization)
{
  const Library& library = metalib.library (component);
  daisy_assert (library.check (parameterization));
  const Frame& frame = library.model (parameterization);
  if (frame.check ("parsed_sequence"))
    return frame.integer ("parsed_sequence");

  return -1;
}

struct object_desc
{
  symbol comp;
  symbol par;
  void operator= (const object_desc& other)
  { 
    comp = other.comp;
    par = other.par;
  }
  object_desc (const object_desc& other)
    : comp (other.comp),
      par (other.par)
  { }
  object_desc (const symbol c, const symbol p)
    : comp (c),
      par (p)
  { }
};


struct sort_by_sequence 
{
  Metalib& metalib;
  
  int operator()(const object_desc& one, const object_desc& two)
  { return sequence_number (metalib, one.comp, one.par) 
      < sequence_number (metalib, two.comp, two.par); }
  sort_by_sequence (Metalib& mlib)
    : metalib (mlib)
  { }
};

void
resequence (Metalib& metalib,
            const symbol component, const symbol parameterization, 
	    const dep_map& dependencies)
{ 
  // Vector with all object to resequence.
  std::vector<object_desc> deps;

  // Add parent.
  deps.push_back (object_desc (component, parameterization));

  // Add dependencies.
  for (dep_map::const_iterator i = dependencies.begin ();
       i != dependencies.end ();
       i++)
    {
      const symbol component = (*i).first;
      const symbol_set& pars = (*i).second;
      for (symbol_set::const_iterator j = pars.begin ();
	   j != pars.end ();
	   j++)
	deps.push_back (object_desc (component, *j));
    }

  // Sort them.
  sort (deps.begin (), deps.end (), sort_by_sequence (metalib));

  // Resequence them.
  for (unsigned int i = 0; i < deps.size (); i++)
    {
      const symbol component = deps[i].comp;
      const symbol parameterization = deps[i].par;
       
      Library& library = metalib.library (component);
      daisy_assert (library.check (parameterization));
      Frame& frame = library.frame (parameterization);
      frame.add ("parsed_sequence", metalib.get_sequence ());
    }
}

// depend.C ends here.
