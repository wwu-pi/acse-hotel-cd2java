package de.wwu.pi.mdsd.umlToApp

import org.eclipse.xtext.generator.IGenerator
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.uml2.uml.Class
import org.eclipse.uml2.uml.Property

import org.eclipse.uml2.uml.Model

class UmlToAppGenerator implements IGenerator {
	static val INTERNAL_MODEL_EXTENSIONS = newArrayList(".library.uml", ".profile.uml", ".metamodel.uml")

	def static isModel(Resource input) {
		!INTERNAL_MODEL_EXTENSIONS.exists(ext|input.getURI.path.endsWith(ext))
	}

	override doGenerate(Resource input, IFileSystemAccess fsa) {
		System::out.println("UmlToAppGenerator.doGenerate called with resource " + input.getURI)
		if (isModel(input)) {
			System::out.println("Generating ...")
			val model = input.contents.head as Model
			val classes = model.ownedElements.filter(typeof(org.eclipse.uml2.uml.Class))
			val entityClasses = classes.filter([cl|cl.appliedStereotypes.exists[s|s.name.equals("En")]])
			var ddl = ""
			for (cl : entityClasses) {
//				val attributeNames = cl.attributes.map([att | att.name])			
//				val attributeTypes = cl.attributes.map([att | att.type.name])
				fsa.generateFile(cl.name + ".java", generateClass(cl))
				ddl = ddl + generateTable(cl)
			}
			fsa.generateFile("Hotel.ddl", ddl)
		}
	}

// generate Java classes with properties, constructor, getters and setters	
	def static generateClass(Class clazz) ''' 
	package data;
	import java.util.*;
	import java.sql.*;
	import java.sql.Date;
	
	// class «clazz.name»
	public class «clazz.name» extends Object{
	    // attributes
	    «FOR att : clazz.attributes»
	      «IF (att.type instanceof Class) && att.multivalued»
	      protected Vector «att.name»s;
	      «ELSE» 
	       protected «att.type.name» «att.name» ;
	      «ENDIF»  
	    «ENDFOR»  
	  
      // constructor
	  public «clazz.name»(
	    «FOR att : clazz.attributes SEPARATOR ','»
	      «IF (att.type instanceof Class) && att.multivalued»
	      Vector «att.name»s
	      «ELSE» 
	      	«att.type.name» «att.name»
	      «ENDIF»  	
	    «ENDFOR»
	  ){
	  «FOR att : clazz.attributes»
	  	 «IF (att.type instanceof Class) && att.multivalued»
	  	 this.«att.name»s = «att.name»s;
	     «ELSE» 
	  	 this.«att.name» = «att.name»;
	     «ENDIF»  	
	  «ENDFOR»
	  }
	  
	  // getters and setters
	  «FOR att : clazz.attributes»
	  	  «IF (att.type instanceof Class) && att.multivalued»
	  	  public Vector get«att.name.toFirstUpper»s() {
	  	  return «att.name»s;}
	  	  
	     «ELSE» 
	  	  public «att.type.name» get«att.name.toFirstUpper»() {
	  	  return «att.name»;}
	  	  
	  	  public void set«att.name.toFirstUpper»(«att.type.name» «att.name»){
	  	  this.«att.name» = «att.name»;}  
	  	  
	     «ENDIF»  	
	  «ENDFOR» 
	  
	  // persist
	  public int persist(){
		Connection conn = null;        
		int pk = 0;
		try { conn = DriverManager.getConnection(global.ConnectionString.get());
	      Statement stmt = conn.createStatement();   
	      stmt.executeUpdate("INSERT INTO «clazz.name» VALUES ("+
	        «FOR att : clazz.attributes»
	          «IF !(att.type instanceof Class) && !att.appliedStereotypes.exists[s | s.name.equals("pk")]»
	          "'"+«att.name»+"'"+ «IF att != clazz.attributes.last» ","+ «ENDIF»
	          «ELSE» 
	            «IF (att.type instanceof Class)»  
	               «IF (att.multivalued == false)»
	               "'"+«att.name».get«att.name.toFirstUpper»No()+"'"+«IF att != clazz.attributes.last» ","+ «ENDIF»	
	               «ENDIF»  
	            «ELSE» 
	            "NULL"+«IF att != clazz.attributes.last» ","+ «ENDIF»
	            «ENDIF» 
	          «ENDIF»        
	        «ENDFOR»")",
        	stmt.RETURN_GENERATED_KEYS);
          ResultSet rs = stmt.getGeneratedKeys();
          if (rs.next()) pk = rs.getInt(1);
          System.out.println("new tuple with primary key "+pk+" inserted into DB");
          conn.close();}
     	catch(SQLException ex){
     	  System.out.println("SQLException: " + ex.getMessage());
		  System.out.println("SQLState: " + ex.getSQLState());
		  System.out.println("VendorError: " + ex.getErrorCode());} 
        return pk;
	}
	
	// finders
	«FOR op : clazz.operations.filter[o | o.name.substring(0,6) == "findBy"]»
	    public static «clazz.name» «op.name»(
	      «FOR par: op.ownedParameters.filter[direction.name() != "RETURN_LITERAL"] SEPARATOR ','» // check
	        «par.type.name» «par.name»
	      «ENDFOR»){
    	«clazz.name» cl = null;
	    Connection conn = null;
	    try {conn =
	    DriverManager.getConnection(global.ConnectionString.get());
	    Statement stmt = conn.createStatement();
	    ResultSet rs = stmt.executeQuery(
	    "SELECT "+
 		         «FOR att: clazz.attributes»
	               «IF !(att.type instanceof Class) || !att.multivalued»
	               "«att.name.toFirstUpper» «IF att != clazz.attributes.last», «ENDIF» "+
	               «ENDIF»
	             «ENDFOR»
	           "FROM «clazz.name» "+
	    "WHERE "+
 		          «FOR par: op.ownedParameters.filter[direction.name() != "RETURN_LITERAL"] SEPARATOR "+\" AND \"+"»
 		          "«par.name.toFirstUpper»  = '"+«par.name»+"'"
	             «ENDFOR»); 		    
	    if (rs.next()){
	    cl = new «clazz.name»(
 		    	  «FOR att: clazz.attributes»
	                «IF !(att.type instanceof Class) || !att.multivalued»
 		    	  rs.get«att.type.name.toFirstUpper»("«att.name.toFirstUpper»")
	                «ELSE» null
	                «ENDIF»
	                «IF att != clazz.attributes.last», «ENDIF»
	              «ENDFOR»);
	    } 	    
	    conn.close();}
	    catch(SQLException ex){ 
	    System.out.println("SQLException: " + ex.getMessage());
	    System.out.println("SQLState: " + ex.getSQLState());
	    System.out.println("VendorError: " + ex.getErrorCode());} 
	    return cl;
	    }
    «ENDFOR»
    
    // other non-trivial methods in model
	«FOR op : clazz.operations.filter[o | o.name.substring(0,6) != "findBy"]»
	public static «op.ownedParameters.filter[direction.name() == "RETURN_LITERAL"].head.type.name» «op.name»(
	  «FOR par: op.ownedParameters.filter[direction.name() != "RETURN_LITERAL"] SEPARATOR ","»
	  «par.type.name»  «par.name»
	  «ENDFOR»){ 
	  	// PROTECTED REGION ID(«clazz.name+"."+op.name») ENABLED START
		/* Insert individual code here */
		«IF op.ownedParameters.filter[direction.name() == "RETURN_LITERAL"].head.type instanceof Class»
		return null;
	    «ELSE» return («op.ownedParameters.filter[direction.name() == "RETURN_LITERAL"].head.type.name») 0;
	    «ENDIF»
		// PROTECTED REGION END
	  }
	«ENDFOR»
}
'''

//   def String toFirstUpper(String str) {
//     str.substring(0,1).toUpperCase() + str.substring(1)
//   }
	// generate DDL for DB table definition
	def static generateTable(Class clazz) ''' 
		CREATE TABLE «clazz.name»(
		  «FOR att : clazz.attributes»
		  	«IF !(att.type instanceof Class)»
		  		«att.name»  «transform(att.type.name)»  «IF isRequired(att)»  NOT NULL  «ENDIF» «IF att != clazz.attributes.last», «ENDIF» 
		  	«ELSE»
		  		«IF att.opposite.multivalued»
		  			«att.name»No INT
		  			«IF att != clazz.attributes.last», «ENDIF»
		  		«ENDIF»
		  	«ENDIF»
		  «ENDFOR»);
	'''

	def static transform(String type) {
		switch type {
			case "int": "INT"
			case "String": "VARCHAR(20)"
			case "Date": "DATE"
		}
	}

	def static isRequired(Property att) {
		false
	}
}
