unit _Assemblies;

uses _Settings;

procedure PrintReferencedAssemblies;
const
    DEFAULT_LIBS: array of string = (
        'System.Speech', // установлена на каждом компе с виндой поэтому ок?
        'mscorlib',
        'System',
        'System.Numerics',
        'System.Core');
begin
    var refs := System.Reflection.Assembly.GetExecutingAssembly.GetReferencedAssemblies;
    var ext_refs := refs.&Where(q -> not (q.Name in DEFAULT_LIBS));
    foreach a: System.Reflection.AssemblyName in ext_refs do
        println('[DEBUG]', 'Подключена сборка', a.Name, a.Version);
    if ext_refs.Any then
        writeln('↑↑↑ в релизе не должно быть всех этих внешних сборок! (прогнать через ilmerge)');
end;

initialization
    if not Console.IsOutputRedirected and DEBUGMODE then PrintReferencedAssemblies;

end. 