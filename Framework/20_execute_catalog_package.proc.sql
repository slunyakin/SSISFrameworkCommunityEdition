/*
© 2016 Andy Leonard
*/

Use SSISDB
go


 -- custom.execute_catalog_package stored procedure
print 'Custom.execute_catalog_package stored procedure'
If Exists(Select s.name + '.' + p.name
          From sys.procedures p
		  Join sys.schemas s
		    On s.schema_id = p.schema_id
		  Where s.name = 'custom'
		    And p.name = 'execute_catalog_package')
 begin
  print ' - Dropping custom.execute_catalog_package stored procedure'
  Drop Procedure custom.execute_catalog_package
  print ' - Custom.execute_catalog_package stored procedure dropped'
 end
print ' - Creating custom.execute_catalog_package stored procedure'
go

/*
SSIS Framework
© 2016 Andy Leonard
*/

Create Procedure custom.execute_catalog_package
  @package_name nvarchar(130)
, @project_name nvarchar(260)
, @folder_name nvarchar(260)
, @logging_level smallint = 1
As

 begin

  -- create an Intent-to-Execute
  declare @execution_id bigint
  exec [SSISDB].[catalog].[create_execution]
     @package_name=@package_name
   , @execution_id=@execution_id OUTPUT
   , @folder_name=@folder_name
   , @project_name=@project_name
   , @use32bitruntime=False
   , @reference_id=NULL

  -- configure the Logging Level
  exec [SSISDB].[catalog].[set_execution_parameter_value]
     @execution_id
   , @object_type=50
   , @parameter_name=N'LOGGING_LEVEL'
   , @parameter_value=@logging_level

  -- configure the Logging Level
  exec [SSISDB].[catalog].[set_execution_parameter_value]
     @execution_id
   , @object_type=50
   , @parameter_name=N'SYNCHRONIZED'
   , @parameter_value=1

  -- Start the execution
  exec [SSISDB].[catalog].[start_execution] @execution_id

  -- Check the result
    declare @res int = (Select Case When [Status] = 7 Then 1
                               Else 0
  	      	                   End As Result
                        From internal.operations
                        Where operation_id = @execution_id)

  -- Return the result
  declare @ErrMsg varchar(4000)
  declare @PackagePath varchar(518) = @folder_name + '\' + @project_name + '\' + @package_name
  If (@res = 0)
   begin
    Set @ErrMsg = @PackagePath + ' execution failed.'
    RaisError(@ErrMsg, 16, 1)
   end

  -- Return result
  Select @res As Result

 end
go

print ' - Custom.execute_catalog_package stored procedure created'
go
