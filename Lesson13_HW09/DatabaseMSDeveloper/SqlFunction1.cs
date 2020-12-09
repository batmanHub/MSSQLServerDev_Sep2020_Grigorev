using System;
using System.Collections;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;

public class UserDefinedFunctions
{
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
        if (passwordLen.IsNull) {
            passwordLen = 6;
        }

        if (isSpecialCharacters.IsNull)
        {
            isSpecialCharacters = true;
        }

        return (generatePasswords(passwordLen.Value,isSpecialCharacters.Value,1)[0]);
    }

    [Microsoft.SqlServer.Server.SqlFunction(
        Name = "GetPasswords",
        TableDefinition = "Password nvarchar(200)",
        FillRowMethodName = "MakeRow")]
    public static IEnumerable getPasswords(SqlInt32 passwordLen, SqlBoolean isSpecialCharacters, SqlInt32 passworsCount)
    {
        if (passwordLen.IsNull)
        {
            passwordLen = 6;
        }

        if (isSpecialCharacters.IsNull)
        {
            isSpecialCharacters = true;
        }

        if (passworsCount.IsNull)
        {
            passworsCount = 1;
        }

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
