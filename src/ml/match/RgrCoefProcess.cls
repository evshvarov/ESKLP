/// Using Python to get logistic regression coefficients
Class ml.match.RgrCoefProcess Extends (Ens.BusinessProcessBPL, isc.py.ens.ProcessUtils)
{

/// Plan id to update coef weights
/// If not specified default query in BPL would be used
Property PlanId As %Integer [ InitialExpression = 1 ];

Parameter SETTINGS = "PlanId:Basic";

Storage Default
{
<Data name="RgrCoefProcessDefaultData">
<Subscript>"RgrCoefProcess"</Subscript>
<Value name="1">
<Value>PlanId</Value>
</Value>
</Data>
<DefaultData>RgrCoefProcessDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

XData EmptyCall
{
<xml>
<call name='' target='isc.py.ens.Operation' async='1'>
<annotation><![CDATA[
]]></annotation>
<request type='isc.py.msg.ExecutionRequest' >
<assign property="callrequest.Code" value='process.GetAnnotation("")' action="set" />
</request>
<response type='isc.py.msg.ExecutionResponse' />
</call>
<sync name='Wait for ' calls='' type='all' />

<call name='' target='isc.py.ens.Operation' async='1'>
<annotation><![CDATA[]]></annotation>
<request type='isc.py.msg.QueryRequest' >
<assign property="callrequest.Query" value='process.GetAnnotation("")' action="set" />
<assign property="callrequest.Variable" value='""' action="set" />
<assign property="callrequest.Type" value='"list"' action="set" />
</request>
<response type='Ens.Response' />
</call>
<sync name='Wait for ' calls='' type='any'/>

</xml>
}

/// BPL Definition
XData BPL [ XMLNamespace = "http://www.intersystems.com/bpl" ]
{
<process language='objectscript' request='Ens.Request' response='Ens.Response' height='2100' width='2000' >
<context>
<property name='score' type='%VarString' instantiate='0' />
<property name='intercept' type='%VarString' instantiate='0' />
<property name='coef' type='%VarString' instantiate='0' />
</context>
<sequence xend='200' yend='1050' >
<call name='Import' target='isc.py.ens.Operation' async='1' xpos='200' ypos='250' >
<annotation><![CDATA[
# Load modules

# from sklearn.linear_model import LogisticRegression

from sklearn.linear_model import LinearRegression
from sklearn import preprocessing
from sklearn.model_selection import train_test_split
from sklearn import metrics

]]></annotation>
<request type='isc.py.msg.ExecutionRequest' >
<assign property="callrequest.Code" value="process.GetAnnotation(&quot;Import&quot;)" action="set" />
</request>
<response type='isc.py.msg.ExecutionResponse' />
</call>
<sync name='Wait for Import' calls='Import' type='all' xpos='200' ypos='350' />
<call name='Load Data' target='isc.py.ens.Operation' async='1' xpos='200' ypos='450' >
<annotation><![CDATA[SELECT CodeLeft, CodeRight, Country, "Decimal", LekForm, ManufName, Ngramm, Nomer, ProdName, Simber, Translit, Trigram, CommonValue, Linked FROM App_MAF.LinkML]]></annotation>
<request type='isc.py.msg.QueryRequest' >
<assign property="callrequest.Query" value="process.GetAnnotation(&quot;Load Data&quot;)" action="set" />
<assign property="callrequest.Variable" value="&quot;df&quot;" action="set" />
<assign property="callrequest.Type" value="&quot;dataframe&quot;" action="set" />
</request>
<response type='Ens.Response' />
</call>
<sync name='Wait for data' calls='Load Data' type='any' xpos='200' ypos='550' />
<call name='Linear regression' target='isc.py.ens.Operation' async='1' xpos='200' ypos='650' >
<annotation><![CDATA[

# Extract Y
Y = df.CommonValue
# Y = df.Linked

# Dropping unneeded variables from trainig data
X = df.drop(columns=['CommonValue', 'CodeLeft', 'CodeRight', 'Linked'])
del df

x_train, x_test, y_train, y_test = train_test_split(X, Y, test_size=0.25, random_state=0)

# _________________
# Train model 

# Create empty Logistic Regression model
#regr = LogisticRegression()

# Create empty Linear Regression model
rgr = LinearRegression()

# Train it
rgr.fit(x_train, y_train)

# __________________
# Test model

# Use score method to get accuracy of model
score = rgr.score(x_test, y_test)

# вектор весов
coef = rgr.coef_

# интерсепт
intercept = rgr.intercept_

]]></annotation>
<request type='isc.py.msg.ExecutionRequest' >
<assign property="callrequest.Code" value="process.GetAnnotation(&quot;Linear regression&quot;)" action="set" />
<assign property="callrequest.Variables" value="&quot;score,coef,intercept&quot;" action="set" />
<assign property="callrequest.Serialization" value="&quot;JSON&quot;" action="set" />
</request>
<response type='isc.py.msg.ExecutionResponse' >
<assign property="context.score" value="callresponse.Variables.GetAt(&quot;score&quot;)" action="set" />
<assign property="context.coef" value="callresponse.Variables.GetAt(&quot;coef&quot;)" action="set" />
<assign property="context.intercept" value="callresponse.Variables.GetAt(&quot;intercept&quot;)" action="set" />
</response>
</call>
<sync name='Wait for Linear regression' calls='Linear regression' type='all' xpos='200' ypos='750' />
<trace name='Results' value='"score: " _ context.score _ ", coef: " _ context.coef _ ", intercept: " _ context.intercept' xpos='200' ypos='850' />
<assign name="Save coeff" property="status" value="##class(App.MAF.Plan).UpdateMetricsWeights(process.PlanId, context.coef, context.intercept, context.score)" action="set" xpos='200' ypos='950' />
</sequence>
</process>
}

}

