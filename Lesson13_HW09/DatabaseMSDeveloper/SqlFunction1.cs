using System;
using System.Collections;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;



public class UserDefinedFunctions
{
    const int defaultPasswordLen = 7;
    const bool defaultAllowSpecialCharacters = false;

    private static List<SqlString> generatePasswords (SqlInt32 passwordLen, SqlBoolean isSpecialCharacters, SqlInt32 passworsCount)
    {
        List<SqlString> result = new List<SqlString>();

        string chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

        if (isSpecialCharacters)
        {
            chars += "~`!@$%^&*(){}<>_";
        }

        Random rnd = new Random();
        int charsLen = chars.Length;
        for (int j = 0; j < passworsCount; j++)
        {
            String curPass = "";
            for (int i = 0; i < passwordLen; i++)
            {
                curPass += chars[rnd.Next(charsLen)];
            }
            result.Add(new SqlString(curPass));

        }
        return result;
    }

    [Microsoft.SqlServer.Server.SqlFunction(
        Name = "GetPassword",
        IsDeterministic = false)]
    public static SqlString getPassword(SqlInt32 passwordLen,SqlBoolean isSpecialCharacters)
    {
        if (passwordLen.IsNull)  passwordLen = defaultPasswordLen;

        if (isSpecialCharacters.IsNull)   isSpecialCharacters = defaultAllowSpecialCharacters;

        return (generatePasswords(passwordLen,isSpecialCharacters,1)[0]);
    }

    [Microsoft.SqlServer.Server.SqlFunction(
        Name = "GetPasswordbyLen",
        IsDeterministic = false)]
    public static SqlString getPasswordByLen(SqlInt32 passwordLen)
    {
        return getPassword(passwordLen, new SqlBoolean(defaultAllowSpecialCharacters));
    }

    [Microsoft.SqlServer.Server.SqlFunction(
    Name = "GetPasswordSimple",
    IsDeterministic = false)]
    public static SqlString getPasswordSimple()
    {
        return getPassword(new SqlInt32(defaultPasswordLen), new SqlBoolean(defaultAllowSpecialCharacters));
    }

    [Microsoft.SqlServer.Server.SqlFunction(
        Name = "GetPasswords",
        TableDefinition = "Password nvarchar(200)",
        FillRowMethodName = "MakeRow")]
    public static IEnumerable getPasswords(SqlInt32 passwordLen, SqlBoolean isSpecialCharacters, SqlInt32 passworsCount)
    {
        if (passwordLen.IsNull)  passwordLen = defaultPasswordLen;

        if (isSpecialCharacters.IsNull)  isSpecialCharacters = defaultAllowSpecialCharacters;

        if (passworsCount.IsNull)  passworsCount = 1;

        List<SqlString> passwords  = generatePasswords(passwordLen.Value, isSpecialCharacters.Value, passworsCount.Value);
        return passwords;

    }

    public static void MakeRow(
    Object obj, out string Password)
    {
        SqlString row = (SqlString)obj;
        Password = row.Value;
    }

}
