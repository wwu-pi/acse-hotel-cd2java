package umlToApp.workflow;

import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
import org.eclipse.xtext.generator.IGenerator;
import org.eclipse.xtext.resource.generic.AbstractGenericResourceRuntimeModule;

import de.wwu.pi.mdsd.umlToApp.UmlToAppGenerator;

public class UmlToAppGeneratorModule extends
		AbstractGenericResourceRuntimeModule {

	@Override
	protected String getLanguageName() {
		return "org.eclipse.uml2.uml.editor.presentation.UMLEditorID";
	}

	@Override
	protected String getFileExtensions() {
		return "uml";
	}
	
	public Class<? extends IGenerator> bindIGenerator() {
		return UmlToAppGenerator.class;
	}
	
	public Class<? extends ResourceSet> bindResourceSet() {
		return ResourceSetImpl.class;
	}

}
